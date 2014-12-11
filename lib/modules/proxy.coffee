###*
 * For test, page injection development.
 * A cross platform Fiddler alternative.
 * Most time used with SwitchySharp.
 * @extends {http-proxy.ProxyServer}
###
Overview = 'proxy'

_ = require 'lodash'
kit = require '../kit'
http = require 'http'

###*
 * Create a Proxy instance.
 * @param  {Object} opts Defaults: `{ }`
 * @return {Proxy} For more, see [node-http-proxy][node-http-proxy]
 * [node-http-proxy]: https://github.com/nodejitsu/node-http-proxy
###
proxy = (opts = {}) ->
	_.defaults opts, {}

	self = {}

	self.agent = new http.Agent

	###*
	 * Use it to proxy one url to another.
	 * @param {http.IncomingMessage} req
	 * @param {http.ServerResponse} res
	 * @param {String} url The target url forced to. Optional.
	 * Such as force 'http://test.com/a' to 'http://test.com/b',
	 * force 'http://test.com/a' to 'http://other.com/a',
	 * force 'http://test.com' to 'other.com'.
	 * @param {Object} opts Other options. Default:
	 * ```coffee
	 * {
	 * 	bps: null # Limit the bandwidth byte per second.
	 * 	globalBps: false # if the bps is the global bps.
	 * 	agent: customHttpAgent
	 * }
	 * ```
	 * @param {Function} err Custom error handler.
	 * @return {Promise}
	###
	self.url = (req, res, url, opts = {}, err) ->
		if _.isObject url
			opts = url
			url = undefined

		_.defaults opts, {
			bps: null
			globalBps: false
			agent: self.agent
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
					{ path } = kit.url.parse(req.path)

					url = 'http://' + url + path

		error = err or (e) ->
			kit.log e.toString() + ' -> ' + req.url.red

		# Normalize the headers
		headers = {}
		for k, v of req.headers
			nk = k.replace(/(\w)(\w*)/g, (m, p1, p2) -> p1.toUpperCase() + p2)
			headers[nk] = v

		stream = if opts.bps == null
			res
		else
			if opts.globalBps
				sockNum = _.keys(opts.agent.sockets).length
				bps = opts.bps / (sockNum + 1)
			else
				bps = opts.bps
			throttle = new kit.require('throttle')(bps)
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
			res.writeHead proxyRes.statusCode, proxyRes.headers

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
		net = kit.require 'net'
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
			kit.log err.toString() + ' -> ' + req.url.red
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
	###
	self.pac = (currHost, ruleHandler) ->
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
