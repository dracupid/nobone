process.env.NODE_ENV = 'development'

nobone = require '../lib/nobone'

port = 8013

# All modules use default options to init.
# If you want don't init a specific module,
# for example 'db' and 'service' module, just exclude it:
#	nb.init {
#		renderer: {}
#	}
# By default it load two module: service, renderer
nb = nobone.create {
	db: { db_path: './test.db' }
	proxy: {}
	renderer: {}
	service: {}
}
# Print all available modules.
nobone.module_defaults().done (list) ->
	nb.kit.log 'module_defaults'
	nb.kit.log list

# Server
nb.service.get '/', (req, res) ->
	# Renderer
	# You can also render coffee, stylus, or define custom handlers.
	nb.renderer.render('bone/client/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ auto_reload: nb.renderer.auto_reload() })

# Launch socket.io and express.js
s = nb.service.listen port

# Kit
# Print out time, log message, time span between two log.
nb.kit.log 'Listen port ' + port

# Static folder to automatically serve coffeescript and stylus.
nb.service.use nb.renderer.static({ root_dir: 'bone/client' })

# Edit the 'bone/client/index.ejs' file, the page should auto reload.
nb.renderer.on 'watch_file', (path) ->
	nb.kit.log 'Watch: '.cyan + path
nb.renderer.on 'file_modified', (path) ->
	nb.kit.log 'Modifed: '.cyan + path

# Database
# Nobone has a build-in file database.
# For more info see: https://github.com/ysmood/jdb
# Here we save 'a' as value 1.
nb.kit.log nb.db
nb.db.exec({
	command: (jdb) ->
		jdb.doc.a = 1
		jdb.save('OK')
}).done (data) ->
	nb.kit.log data

# Proxy
# Proxy path to specific url.
# For more info, see here: https://github.com/nodejitsu/node-http-proxy
nb.service.get '/proxy.*', (req, res) ->
	# If you visit "http://127.0.0.1:8013/proxy.js",
	# it'll return the "http://127.0.0.1:8013/main.js" from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, "http://127.0.0.1:#{port}/main." + req.params[0]

close = ->
	# Release all the resources.
	nb.close().done ->
		nb.kit.log 'Peacefully closed.'
