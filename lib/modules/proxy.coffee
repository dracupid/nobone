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
		 * @param {String} url The target url
		 * @param {Object} opts Other options.
		 * @param {Function} err Error handler.
		###
		url: (req, res, url, opts = {}, err) ->
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
		 * Simulate simple network delay.
		 * @param {http.IncomingMessage} req
		 * @param {http.ServerResponse} res
		 * @param {Number} delay In milliseconds.
		 * @param {Object} opts Other options.
		 * @param {Function} err Error handler.
		###
		delay: (req, res, delay, opts = {}, err) ->
			url = kit.url.parse req.originalUrl
			setTimeout(->
				proxy.web(req, res, _.defaults(opts, {
					proxyTimeout: delay * 10
					timeout: delay * 10
					target: url.format()
				}), (e) ->
					if not err
						kit.log e.toString() + ' -> ' + req.url.red
					else
						err e
				)
			, delay)

		###*
		 * Http CONNECT method tunneling proxy helper.
		 * @param  {String} host The host force to. It's optional.
		 * @param  {Int} port The port force to. It's optional.
		 * @return {Function} A connect helper.
		 * @example
		 * ```coffee
		 * nobone = require 'nobone'
		 * { proxy, service } = nobone { proxy:{}, service: {} }
		 *
		 * # Directly connect to the original site.
		 * service.server.on 'connect', proxy.connect()
		 * ```
		###
		connect: (host, port) ->
			(req, sock, head) ->
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

				sock.on 'error', (err) ->
					kit.log err
					sock.end()
				psock.on 'error', (err) ->
					kit.log err
					psock.end()

		###*
		 * HTTP/HTTPS Agents for tunneling proxies.
		 * See the project https://github.com/koichik/node-tunnel
		###
		tunnel
	}

proxy.defaults = {}

module.exports = proxy
