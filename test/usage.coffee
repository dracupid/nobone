nb = require '../lib/nobone'

# Server lib
nb.service.get '/', (req, res) ->

	# Renderer lib
	nb.renderer.render('test/sample.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ OK: "NoBone" })

port = 8013
nb.service.listen port

# Kit lib
nb.kit.log 'Listen port ' + port


# Static folder to automatically serve coffeescript and stylus.
nb.service.use nb.renderer.static({ root_dir: 'test' })
