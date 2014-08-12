process.env.NODE_ENV = 'development'

nobone = require 'nobone'

port = 8013

# If you want to init without a specific module,
# for example 'db' and 'service' module, just exclude them:
# 	nobone {
# 		renderer: {}
# 	}
# By default it only loads two modules: `service` and `renderer`.
nb = nobone {
	db: { db_path: './test.db' }
	proxy: {}
	renderer: {}
	service: {}
}

# Print all available modules with their default options.
nobone.module_defaults().done (list) ->
	nb.kit.log 'module_defaults'
	nb.kit.log list

# Service
nb.service.get '/', (req, res) ->
	# Renderer
	# It will auto-find the 'test/test_app/index.ejs', and render it to html.
	# You can also render coffee, stylus, less, sass, markdown, or define custom handlers.
	# When you modifies the `test/test_app/index.ejs`, the page will auto-reload.
	nb.renderer.render('test/test_app/index.html')
	.done (tpl_func) ->
		res.send tpl_func({ name: 'nobone' })

# Launch express.js
nb.service.listen port, ->
	# Kit
	# A smarter log helper.
	nb.kit.log 'Listen port ' + port

	# Open default browser.
	nb.kit.open 'http://127.0.0.1:' + port

# Static folder for auto-service of coffeescript and stylus, etc.
nb.service.use nb.renderer.static('test/test_app')

# Database
# Nobone has a build-in file database.
# Here we save 'a' as value 1.
nb.db.loaded.done ->
	nb.db.exec (jdb) ->
		jdb.doc.a = 1
		jdb.save('DB OK')
	.done (data) ->
		nb.kit.log data

# Proxy
# Proxy path to specific url.
nb.service.get '/proxy.*', (req, res) ->
	# If you visit "http://127.0.0.1:8013/proxy.js",
	# it'll return the "http://127.0.0.1:8013/main.js" from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, "http://127.0.0.1:#{port}/main." + req.params[0]

close = ->
	# Release all the resources.
	nb.close().done ->
		nb.kit.log 'Peacefully closed.'
