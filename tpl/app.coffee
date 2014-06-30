nb = require 'nobone'

nb.init()

nb.service.use(
	nb.renderer.static({ root_dir: __dirname + '/client' })
)

nb.service.get '/', (req, res) ->
	nb.renderer.render(__dirname + '/client/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({
			auto_reload: nb.renderer.auto_reload()
		})

port = 8013
nb.service.server.listen port
nb.kit.log 'Listen port ' + port
