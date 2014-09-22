nobone = require '../lib/nobone'
{ kit, service, renderer } = nobone()

port = 8215

file_path = './assets/img/nobone.png'

service.get '/stream', (req, res) ->
	kit.readFile file_path
	.done (data) ->
		res.type 'png'
		res.send data

mem_cache = kit.fs.readFileSync file_path
service.get '/memory', (req, res) ->
	renderer.render file_path
	.done (data) ->
		res.type 'png'
		res.send data

service.listen port, ->
	kit.log 'Listen: ' + port
