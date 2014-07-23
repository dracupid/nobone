###*
 * For test, page injection development.
 * A cross platform Fiddler alternative.
 * Most time used with SwitchySharp.
 * @extends {http-proxy.ProxyServer}
###
Overview = 'proxy'

_ = require 'lodash'
kit = require '../kit'
http_proxy = require 'http-proxy'
tunnel = require 'tunnel'
http = require 'http'

###*
 * Create a Proxy instance.
 * @param  {Object} opts Defaults: `{ }`
 * @return {Proxy} For more, see https://github.com/nodejitsu/node-http-proxy
###
proxy = (opts = {}) ->
	_.defaults opts, proxy.defaults

	proxy = http_proxy.createProxyServer opts

	_.extend proxy, {
		###*
		 * Use it to proxy one url to another.
		 * @param {http.IncomingMessage} req
		 * @param {http.ServerResponse} res
		 * @param {String} url The target url force to.
		 * @param {Object} opts Other options.
		 * @param {Function} err Custom error handler.
		###
		url: (req, res, url, opts = {}, err) ->
			if not url
				url = req.url

			if typeof url == 'string'
				url = kit.url.parse url

			req.url = url

			proxy.web(req, res, _.defaults(opts, {
				target: url.format()
			}) , (e) ->
				if not err
					kit.log e.toString() + ' -> ' + req.url.red
				else
					err e
			)

		###*
		 * Http CONNECT method tunneling proxy helper.
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
		connect: (req, sock, head, host, port, err) ->
			net = kit.require 'net'
			h = host or req.headers.host
			p = port or req.url.match(/:(\d+)$/)[1] or 443

			psock = new net.Socket
			psock.connect p, h, ->
				psock.write head
				sock.write "HTTP/" + req.httpVersion + " 200 Connection established\r\n\r\n"

			sock.on 'data', (buf) ->
				psock.write buf
			psock.on 'data', (buf) ->
				sock.write buf

			sock.on 'end', ->
				psock.end()
			psock.on 'end', ->
				sock.end()

			error = err or (err, socket) ->
				kit.log err.toString() + ' -> ' + req.url.red
				socket.end()

			sock.on 'error', (err) ->
				error err, sock
			psock.on 'error', (err) ->
				error err, psock

		###*
		 * HTTP/HTTPS Agents for tunneling proxies.
		 * See the project https://github.com/koichik/node-tunnel
		###
		tunnel
	}

proxy.defaults = {}

module.exports = proxy
