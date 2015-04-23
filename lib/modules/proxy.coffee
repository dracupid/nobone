###*
 * For test, page injection development.
 * A cross-platform programmable Fiddler alternative.
###
Overview = 'proxy'

kit = require '../kit'
{ _ } = kit
http = require 'http'

###*
 * Create a Proxy instance.
 * @param  {Object} opts Defaults: `{ }`
 * @return {Proxy}
###
proxy = (opts = {}) ->
	_.defaults opts, {}

	self = {}

	self.agent = new http.Agent

	###*
	 * Use it to proxy one url to another.
	 * @param {http.IncomingMessage} req Also supports Express.js.
	 * @param {http.ServerResponse} res Also supports Express.js.
	 * @param {String | Object} url The target url forced to. Optional.
	 * Such as force 'http://test.com/a' to 'http://test.com/b',
	 * force 'http://test.com/a' to 'http://other.com/a',
	 * force 'http://test.com' to 'other.com'.
	 * It can also be an url object. Such as
	 * `{ protocol: 'http:', host: 'test.com:8123', pathname: '/a/b', query: 's=1' }`.
	 * @param {Object} opts Other options. Default:
	 * ```coffee
	 * {
	 * 	# Limit the bandwidth byte per second.
	 * 	bps: null
	 *
	 * 	# if the bps is the global bps.
	 * 	globalBps: false
	 *
	 * 	agent: customHttpAgent
	 *
	 * 	# You can hack the headers before the proxy send it.
	 * 	handleReqHeaders: (headers) -> headers
	 * 	handleResHeaders: (headers) -> headers
	 * }
	 * ```
	 * @param {Function} err Custom error handler.
	 * @return {Promise}
	 * @example
	 * ```coffee
	 * nobone = require 'nobone'
	 * { proxy, service } = nobone { proxy:{}, service: {} }
	 *
	 * service.post '/a', (req, res) ->
	 * 	proxy.url req, res, 'a.com', (err) ->
	 * 		kit.log err
	 *
	 * service.get '/b', (req, res) ->
	 * 	proxy.url req, res, '/c'
	 *
	 * service.get '/a.js', (req, res) ->
	 * 	proxy.url req, res, 'http://b.com/c.js'
	 *
	 * # Transparent proxy.
	 * service.use proxy.url
	 * ```
	###
	self.url = (req, res, url, opts = {}, err) ->
		kit.require 'url'

		_.defaults opts, {
			bps: null
			globalBps: false
			agent: self.agent
			handleReqHeaders: (headers) -> headers
			handleResHeaders: (headers) -> headers
		}

		if not url
			url = req.url

		if _.isObject url
			url = kit.url.format url
		else
			sepIndex = url.indexOf('/')
			switch sepIndex
				# such as url is '/get/page'
				when 0
					url = 'http://' + req.headers.host + url
				# such as url is 'test.com'
				when -1
					{ path } = kit.url.parse(req.url)

					url = 'http://' + url + path

		error = err or (e) ->
			cs = kit.require 'colors/safe'
			kit.log e.toString() + ' -> ' + cs.red req.url

		# Normalize the headers
		headers = {}
		for k, v of req.headers
			nk = k.replace(/(\w)(\w*)/g, (m, p1, p2) -> p1.toUpperCase() + p2)
			headers[nk] = v

		headers = opts.handleReqHeaders headers

		stream = if opts.bps == null
			res
		else
			if opts.globalBps
				sockNum = _.keys(opts.agent.sockets).length
				bps = opts.bps / (sockNum + 1)
			else
				bps = opts.bps

			throttle = new kit.requireOptional('throttle', __dirname)(bps)

			throttle.pipe res
			throttle

		p = kit.request {
			method: req.method
			url
			headers
			reqPipe: req
			resPipe: stream
			autoUnzip: false
			agent: opts.agent
		}

		p.req.on 'response', (proxyRes) ->
			res.writeHead(
				proxyRes.statusCode
				opts.handleResHeaders proxyRes.headers
			)

		p.catch error

	###*
	 * Http CONNECT method tunneling proxy helper.
	 * Most times used with https proxing.
	 * @param {http.IncomingMessage} req
	 * @param {net.Socket} sock
	 * @param {Buffer} head
	 * @param {String} host The host force to. It's optional.
	 * @param {Int} port The port force to. It's optional.
	 * @param {Function} err Custom error handler.
	 * @example
	 * ```coffee
	 * nobone = require 'nobone'
	 * { proxy, service } = nobone { proxy:{}, service: {} }
	 *
	 * # Directly connect to the original site.
	 * service.server.on 'connect', proxy.connect
	 * ```
	###
	self.connect = (req, sock, head, host, port, err) ->
		net = kit.require 'net', __dirname
		h = host or req.headers.host
		p = port or req.url.match(/:(\d+)$/)[1] or 443

		psock = new net.Socket
		psock.connect p, h, ->
			psock.write head
			sock.write "
				HTTP/#{req.httpVersion} 200 Connection established\r\n\r\n
			"

		sock.pipe psock
		psock.pipe sock

		error = err or (err, socket) ->
			cs = kit.require 'colors/safe'
			kit.log err.toString() + ' -> ' + cs.red req.url
			socket.end()

		sock.on 'error', (err) ->
			error err, sock
		psock.on 'error', (err) ->
			error err, psock

	###*
	 * A pac helper.
	 * @param {String} currHost The current host for proxy server. It's optional.
	 * @param  {Function} ruleHandler Your custom pac rules.
	 * It gives you three helpers.
	 * ```coffee
	 * url # The current client request url.
	 * host # The host name derived from the url.
	 * currHost = 'PROXY host:port;' # Nobone server host address.
	 * direct =  "DIRECT;"
	 * match = (pattern) -> # A function use shExpMatch to match your url.
	 * proxy = (target) -> # return 'PROXY target;'.
	 * ```
	 * @return {Function} Express Middleware.
	 * ```coffee
	 * nobone = require 'nobone'
	 * { proxy, service } = nobone { proxy:{}, service: {} }
	 *
	 * service.get '/pac', proxy.pac ->
	 * 	if match 'http://a.com/*'
	 * 		currHost
	 * 	else if url == 'http://c.com'
	 * 		proxy 'd.com:8123'
	 * 	else
	 * 		direct
	 * ```
	###
	self.pac = (currHost, ruleHandler) ->
		kit.require 'url', __dirname

		if _.isFunction currHost
			ruleHandler = currHost
			currHost = null

		(req, res, next) ->
			addr = req.socket.address()
			currHost ?= "#{addr.address}:#{addr.port}"
			url = kit.url.parse(req.url)
			url.host ?= req.headers.host
			kit.log url
			if url.host != currHost
				return next()

			pacStr = """
				FindProxyForURL = function (url, host) {
					var currHost = "PROXY #{currHost};";
					var direct = "DIRECT;";
					var match = function (pattern) {
						return shExpMatch(url, pattern);
					};
					var proxy = function (target) {
						return 'PROXY ' + target + ';';
					};

					return (#{ruleHandler.toString()})();
				}
			"""

			res.set 'Content-Type', 'application/x-ns-proxy-autoconfig'
			res.send pacStr

	return self

module.exports = proxy
