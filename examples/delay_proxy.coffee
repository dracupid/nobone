nobone = require 'nobone'

nb = nobone({
	service: {}
	proxy: {}
})

# Delay http requests.
nb.service.use (req, res) ->
	nb.kit.log req.url
	# Each connection delay for 1 second.
	nb.proxy.delay req, res, 1000


# Delay https requests.
nb.service.server.on 'connect', (req, sock, head) ->
	nb.kit.log req.url
	agent = nb.proxy.connect()
	setTimeout ->
		agent req, sock, head
	, 1000

nb.service.listen 8123
