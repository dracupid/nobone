nobone = require 'nobone'

nb = nobone({
	service: {}
	proxy: {}
})

nb.service.use (req, res) ->
	nb.kit.log req.url
	nb.proxy.delay req, res, 1000

nb.service.listen 8013
