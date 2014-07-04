_ = require 'lodash'
kit = require '../kit'
http_proxy = require 'http-proxy'
http = require 'http'

###*
 * For test, page injection development.
 * A cross platform Fiddler alternative.
 * Most time used with SwitchySharp.
 * @param  {Object} opts Defaults: `{}`
 * @return {Proxy <- http-proxy} For more, see https://github.com/nodejitsu/node-http-proxy
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
	}

proxy.defaults = {}

module.exports = proxy
