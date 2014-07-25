nobone = require 'nobone'

nb = nobone()

nb.service.get '/', (req, res) ->
	nb.renderer.render(__dirname + '/index.ejs', {})
	.done (html) ->
		res.send html

nb.service.use nb.renderer.static('client')

port = 8013
nb.service.listen port, ->
	nb.kit.log 'Listen port ' + port
	nb.kit.open 'http://127.0.0.1:' + port
