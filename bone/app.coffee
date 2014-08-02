{
	kit
	service
	renderer
	conf
} = require './lib'

service.get '/', (req, res) ->
	renderer.render 'views/index.ejs'
	.done (tpl) ->
		res.send tpl()

service.use renderer.static('client')
service.use renderer.static('bower_components')

service.listen conf.port, ->
	kit.log "App: #{conf.name} v#{conf.version}".cyan
	kit.log "Listen port: #{conf.port}".yellow
