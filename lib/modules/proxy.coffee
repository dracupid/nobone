_ = require 'lodash'
kit = require '../kit'
http_proxy = require 'http-proxy'
http = require 'http'

###*
 * For test, page injection development.
 * @param  {object} opts Defaults: `{}`
 * @return {proxy} See https://github.com/nodejitsu/node-http-proxy
 * I extend only on function to it `url`. Use it to proxy one url
 * to another.
###
module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	proxy = http_proxy.createProxyServer opts.proxy

	_.extend proxy, {
		url: (req, res, url) ->
			if typeof url == 'string'
				url = kit.url.parse url

			req.url = url

			proxy.web req, res, {
				target: url.format()
			}
	}

module.exports.defaults = {}
