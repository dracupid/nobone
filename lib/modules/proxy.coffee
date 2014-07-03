_ = require 'lodash'
kit = require '../kit'
http_proxy = require 'http-proxy'
http = require 'http'

###*
 * For test, page injection development.
 * A cross platform Fiddler alternative.
 * Most time used with SwitchySharp.
 * @param  {object} opts Defaults: `{}`
 * @return {proxy} For more, see https://github.com/nodejitsu/node-http-proxy
###
module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	proxy = http_proxy.createProxyServer opts.proxy

	_.extend proxy, {
		###*
		 * Use it to proxy one url to another.
		 * @param  {http.IncomingMessage} req
		 * @param  {http.ServerResponse} res
		 * @param  {string} url The target url
		###
		url: (req, res, url) ->
			if typeof url == 'string'
				url = kit.url.parse url

			req.url = url

			proxy.web req, res, {
				target: url.format()
			}
	}

module.exports.defaults = {}
