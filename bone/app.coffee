nobone = require 'nobone'

nb = nobone.create()

nb.service.get '/', (req, res) ->
	nb.renderer.render(__dirname + '/client/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({
			auto_reload: nb.renderer.auto_reload()
		})

port = 8013
nb.service.listen port
nb.kit.log 'Listen port ' + port
