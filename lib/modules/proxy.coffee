###*
 * For test, page injection development.
 * A cross platform Fiddler alternative.
 * Most time used with SwitchySharp.
 * @extends {http-proxy.ProxyServer}
###
Overview = 'proxy'

_ = require 'lodash'
kit = require '../kit'

###*
 * Create a Proxy instance.
 * @param  {Object} opts Defaults: `{ }`
 * @return {Proxy} For more, see [node-http-proxy][node-http-proxy]
 * [node-http-proxy]: https://github.com/nodejitsu/node-http-proxy
###
proxy = (opts = {}) ->
	_.defaults opts, {}

	self = {}

	###*
	 * Use it to proxy one url to another.
	 * @param {http.IncomingMessage} req
	 * @param {http.ServerResponse} res
	 * @param {String} url The target url force to.
	 * @param {Object} opts Other options.
	 * @param {Function} err Custom error handler.
	 * @return {Promise}
	###
	self.url = (req, res, url, opts = {}, err) ->
		_.defaults opts, {
			bps: null
		}
		if not url
			url = req.url

		if _.isObject url
			url = kit.url.format url

		error = err or (e) ->
			kit.log e.toString() + ' -> ' + req.url.red

		if opts.bps != null
			throttle = new kit.require('throttle')(opts.bps)
			res = throttle.pipe res

		p = kit.request {
			url
			headers: req.headers
			req_pipe: req
			res_pipe: res
			auto_unzip: false
		}

		p.req.on 'response', (proxy_res) ->
			res.writeHead proxy_res.statusCode, proxy_res.headers

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
	 * ```coffeescript
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
	 * @param {String} curr_host The current host for proxy server. It's optional.
	 * @param  {Function} rule_handler Your custom pac rules.
	 * It gives you three helpers.
	 * ```coffeescript
	 * url # The current client request url.
	 * host # The host name derived from the url.
	 * curr_host = 'PROXY host:port;' # Nobone server host address.
	 * direct =  "DIRECT;"
	 * match = (pattern) -> # A function use shExpMatch to match your url.
	 * proxy = (target) -> # return 'PROXY target;'.
	 * ```
	 * @return {Function} Express Middleware.
	###
	self.pac = (curr_host, rule_handler) ->
		if _.isFunction curr_host
			rule_handler = curr_host
			curr_host = null

		(req, res, next) ->
			addr = req.socket.address()
			curr_host ?= "#{addr.address}:#{addr.port}"
			url = kit.url.parse(req.url)
			url.host ?= req.headers.host
			kit.log url
			if url.host != curr_host
				return next()

			pac_str = """
				FindProxyForURL = function (url, host) {
					var curr_host = "PROXY #{curr_host};";
					var direct = "DIRECT;";
					var match = function (pattern) {
						return shExpMatch(url, pattern);
					};
					var proxy = function (target) {
						return 'PROXY ' + target + ';';
					};

					return (#{rule_handler.toString()})();
				}
			"""

			res.set 'Content-Type', 'application/x-ns-proxy-autoconfig'
			res.send pac_str

	return self

module.exports = proxy
