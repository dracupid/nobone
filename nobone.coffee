###
	This is the main entrance of the project.
###

_init_timestamp = Date.now()

global.NB = {}

require './sys/module'

class NB.Nobone extends NB.Module
	constructor: ->
		super

		NB.nobone = @

		@init_modules()

		@init_global_router()

		if NB.conf.auto_reload_page
			@init_auto_reload_page()

	init_global_router: ->
		@set_static_dir 'bower_components'
		@set_static_dir 'assets'
		NB.app.use '/usr', NB.express.static('usr')

		NB.app.use '/favicon.ico', (req, res) ->
			res.sendfile 'assets/img/NB.png'

		NB.app.use(@show_404)

	init_modules: ->
		for name, path of NB.conf.modules
			m = name.match /^(.+)\.(.+)$/
			namespace = m[1]
			class_name = m[2]

			ns = global[namespace] ?= {}
			require path

			ns[class_name.toLowerCase()] = new ns[class_name]

			console.log ">> Load module: #{name}:#{path}".c('green')

	init_database: ->
		require './sys/database'
		@db = new NB.Database

	init_storage: ->
		require './sys/storage'
		NB.storage = new NB.Storage

	init_api: ->
		require './sys/api'
		NB.api = new NB.Api

	init_auto_reload_page: ->
		# Auto reload page when file changed.

		io = NB.io.of('/auto_reload_page').on 'connection', ->

		NB.nobone.emitter.on 'code_reload', (path) ->
			io.emit 'code_reload', path

	show_404: (req, res, next) =>
		if _.find_route(NB.app.routes, req.path)
			next()
			return

		data = {
			head: @r.render('assets/ejs/head.ejs')
			url: req.originalUrl
		}
		res.status(404)
		res.send @r.render('assets/ejs/404.ejs', data)
		console.error ('>> 404: ' + req.originalUrl).c('red')

	launch: ->
		NB.server.listen NB.conf.port
		console.log ("""
			*** #{NB.package.name.toUpperCase()} #{NB.package.version} ***
			>> Node version: #{process.version}
			>> Start at port: #{NB.conf.port}
			>> Date: #{_.t}
		""").c('cyan')


# Launch the application.
new NB.Nobone

NB.nobone.launch()

console.log ">> Took #{Date.now() - _init_timestamp}ms to startup.".c('cyan')