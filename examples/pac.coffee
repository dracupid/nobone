nobone = require 'nobone'

{ kit, proxy, service } = nobone {
	service: {}
	proxy: {}
}

service.use (req, res, next) ->
	# access log
	kit.log req.url
	next()

service.get '/pac', proxy.pac ->
	switch true
		when match 'http://www.baidu.com/*'
			curr_host
		else
			direct

service.use (req, res) ->
	proxy.url req, res

service.listen 8013