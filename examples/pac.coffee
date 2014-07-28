nobone = require 'nobone'

{ kit, proxy, service, renderer } = nobone {
	service: {}
	renderer: {}
	proxy: {}
}

service.get '/pac', proxy.pac ->
	switch true
		when match 'http://www.baidu.com/*'
			curr_host
		else
			direct

service.use (req, res) ->
	kit.log req.url
	proxy.url req, res

service.listen 8013