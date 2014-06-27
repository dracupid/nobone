nb = require '../lib/nobone'

# Server
nb.service.get '/', (req, res) ->

	# Renderer
	# You can also render coffee, stylus, or define custom handlers.
	nb.renderer.render('test/sample.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ OK: "NoBone" })

port = 8013
nb.service.listen port

# Kit
# Print out time, log message, time span between two log.
nb.kit.log 'Listen port ' + port


# Static folder to automatically serve coffeescript and stylus.
nb.service.use nb.renderer.static()

# Log out all the handlers. You can define your own.
console.dir nb.renderer.code_handlers

# Use socket.io
nb.service.io.emit 'msg', 'NoBone'

