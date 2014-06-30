_ = require 'lodash'
kit = require '../kit'
http_proxy = require 'http-proxy'
http = require 'http'

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
