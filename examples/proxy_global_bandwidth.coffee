nobone = require 'nobone'

{ proxy, kit, service } = nobone({
	service: {}
	proxy: {}
})

service.use (req, res) ->
	kit.log req.url

	# Limit the global bandwidth to 100KB/s.
	proxy.url req, res, {
		bps: 100 * 1024
		global_bps: true
	}

service.listen 8123
