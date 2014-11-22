{
	kit
	service
	renderer
	conf
} = require './lib'

service.get '/', (req, res) ->
	renderer.render 'views/index.html'
	.done (tpl) ->
		res.send tpl()

service.use renderer.static('client')
service.use renderer.static('bowerComponents')

service.listen conf.port, ->
	kit.log "App: #{conf.name} v#{conf.version}".cyan
	kit.log "Listen port: #{conf.port}".yellow
