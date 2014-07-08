nobone = require '../lib/nobone'

nb = nobone({
	service: {}
	proxy: {}
})

nb.service.use (req, res) ->
	nb.proxy.delay req, res, 500


nb.service.listen 8013
