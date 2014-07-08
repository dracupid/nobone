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
http = require 'http'

###*
 * Create a Proxy instance.
 * @param  {Object} opts Defaults: `{}`
 * @return {Proxy} For more, see https://github.com/nodejitsu/node-http-proxy
###
proxy = (opts = {}) ->
	_.defaults opts, proxy.defaults

	proxy = http_proxy.createProxyServer opts.proxy

	_.extend proxy, {
		###*
		 * Use it to proxy one url to another.
		 * @param  {http.IncomingMessage} req
		 * @param  {http.ServerResponse} res
		 * @param  {String} url The target url
		###
		url: (req, res, url) ->
			if typeof url == 'string'
				url = kit.url.parse url

			req.url = url

			proxy.web req, res, {
				target: url.format()
			}

		###*
		 * Simulate simple network delay.
		 * @param  {http.IncomingMessage} req
		 * @param  {http.ServerResponse} res
		 * @param  {Number} delay In milliseconds.
		###
		delay: (req, res, delay) ->
			url = kit.url.parse req.originalUrl
			setTimeout(->
				proxy.web req, res, {
					target: url.format()
				}
			, delay)
	}

proxy.defaults = {}

module.exports = proxy
