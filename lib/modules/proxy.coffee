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
 * @return {Proxy} For more, see [node-http-proxy][0]
 * [0]: https://github.com/nodejitsu/node-http-proxy
###
proxy = (opts = {}) ->
	_.defaults opts, proxy.defaults

	self = require('http-proxy').createProxyServer opts

	###*
	 * Use it to proxy one url to another.
	 * @param {http.IncomingMessage} req
	 * @param {http.ServerResponse} res
	 * @param {String} url The target url force to.
	 * @param {Object} opts Other options.
	 * @param {Function} err Custom error handler.
	###
	self.url = (req, res, url, opts = {}, err) ->
		if not url
			url = req.url

		if typeof url == 'string'
			url = kit.url.parse url

		req.url = url

		error = err or (e) ->
			kit.log e.toString() + ' -> ' + req.url.red

		self.web(req, res, _.defaults(opts, {
			target: url.format()
		}) , (e) ->
			error e
		)

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
	 * @param  {Function} rule_handler Your custom pac rules.
	 * It gives you three helpers.
	 * ```coffee
	 * curr_host = 'PROXY host:port;' # Nobone server host address.
	 * direct =  "DIRECT;"
	 * match = (pattern) -> # A function use shExpMatch to match your url.
	 * ```
	 * @param {String} curr_host The current host for proxy server.
	 * @return {Function} Express Middleware.
	###
	self.pac = (rule_handler, curr_host) ->
		(req, res, next) ->
			addr = req.socket.address()
			curr_host ?= "#{addr.address}:#{addr.port}"
			if req.headers.host != curr_host
				return next()

			pac_str = """
				FindProxyForURL = function (url, host) {
					var curr_host = "PROXY #{curr_host};";
					var direct = "DIRECT;";
					var match = function (pattern) {
						return shExpMatch(url, pattern);
					};

					return (#{rule_handler.toString()})();
				}
			"""

			res.set 'Content-Type', 'application/x-ns-proxy-autoconfig'
			res.send pac_str

	###*
	 * HTTP/HTTPS Agents for tunneling proxies.
	 * See the project [node-tunnel][0]
	 * [0]: https://github.com/koichik/node-tunnel
	###
	self.tunnel = require 'tunnel'

	return self

proxy.defaults = {}

module.exports = proxy
