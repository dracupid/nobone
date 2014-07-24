nobone = require 'nobone'

{ proxy, kit, service } = nobone({
	service: {}
	proxy: {}
})

# Delay http requests.
service.use (req, res) ->
	kit.log req.url

	switch req.url

		# You can force the destination url.
		when 'http://www.baidu.com/img/bdlogo.gif'
			proxy.url req, res, 'http://ysmood.org/favicon.ico'

		# Hack the content.
		when 'http://www.baidu.com'
			kit.request req.url
			.done (body) ->
				res.send body.replace(/百度一下/g, 'ys 一下')

		# Delay all other connections for 1 second.
		else
			setTimeout ->
				proxy.url req, res
			, 1000


# Delay https requests.
service.server.on 'connect', (req, sock, head) ->
	kit.log req.url
	setTimeout ->
		proxy.connect req, sock, head
	, 1000

service.listen 8123

# t = nobone()

# t.service.use (req, res) ->
# 	kit.log req.headers

# t.service.listen 8124
