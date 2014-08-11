process.env.NODE_ENV = 'development'

_ = require 'lodash'
cmder = require 'commander'

is_action = false

defaults = {
	port: 8013
	host: '0.0.0.0'
	root_dir: './'
}

cmder
	.usage """[action] [options] [root_dir or coffee_file or js_file].\
		\n
		    Default root_dir is current folder.
		    For the js or coffee entrance file, you could require any npm lib in nobone's dependencies,
		    You can use "var _ = require('lodash')" without "npm install lodash" before.
	"""
	.option '-p, --port <port>', "Server port. Default is #{defaults.port}.", (d) -> +d
	.option '--host <host>', "Host to listen to. Default is #{defaults.host} only."
	.option '-w, --watch <list>', "Watch list to auto-restart server. String or JSON array.", (list) ->
		try
			return JSON.parse list
		catch
			return [list]
	.option '-v, --ver', 'Print version.'
	.option '-d, --doc', 'Open the web documentation.'

cmder
	.command 'bone <dest_dir>'
	.description 'A guid to create server scaffolding.'
	.action (dest_dir, opts) ->
		is_action = true

		nobone = require './nobone'
		{ kit, renderer } = nobone()
		conf = null
		package_path = null

		kit.mkdirs dest_dir
		.then ->
			dest_dir = kit.fs.realpathSync dest_dir
			package_path = kit.path.join(dest_dir, 'package.json')
			kit.outputFile package_path, '{"main": "app.coffee"}'
		.then ->
			kit.spawn 'npm', ['init'], {
				cwd: dest_dir
			}
		.then ->
			kit.readFile package_path
		.then (str) ->
			conf = JSON.parse str
			conf.scripts = {
				test: "cake test"
				install: "cake setup"
			}
			kit.outputFile package_path, JSON.stringify(conf, null, 2)
		.then ->
			conf.class_name = conf.name[0].toUpperCase() + conf.name[1..]
			kit.generate_bone {
				src_dir: kit.path.normalize(__dirname + '/../bone')
				dest_dir
				data: conf
			}
		.then ->
			kit.log 'npm install...'.cyan
			kit.spawn 'npm', ['install', '-S', 'q', 'coffee-script', 'lodash', 'bower', 'nobone'], {
				cwd: dest_dir
			}
		.then ->
			kit.spawn 'npm', ['install', '--save-dev', 'mocha', 'benchmark'], {
				cwd: dest_dir
			}
		.then ->
			kit.spawn dest_dir + '/node_modules/.bin/bower', ['init'], {
				cwd: dest_dir
			}
		.then ->
			kit.log 'bower install...'.cyan
			kit.spawn dest_dir + '/node_modules/.bin/bower', ['install', '-S', 'lodash'], {
				cwd: dest_dir
			}
		.then ->
			kit.spawn 'npm', ['run-script', 'install'], {
				cwd: dest_dir
			}
		.then ->
			kit.rename dest_dir + '/npmignore', dest_dir + '/.npmignore'
		.then ->
			kit.rename dest_dir + '/gitignore', dest_dir + '/.gitignore'
		.then ->
			kit.spawn 'git', ['init'], { cwd: dest_dir }
		.then ->
			kit.spawn 'git', ['add', '--all'], { cwd: dest_dir }
		.then ->
			kit.spawn 'git', ['commit', '-m', 'init'], { cwd: dest_dir }
		.catch (err) ->
			if err.message.indexOf('ENOENT') == 0
				kit.log 'Canceled'.yellow
			else
				throw err
		.done ->
			kit.log 'Scaffolding done.'.green

cmder.parse process.argv

init = ->
	if cmder.ver
		console.log require('../package').version
		return

	_.defaults cmder, defaults

	nobone = require './nobone'
	kit = nobone.kit

	if cmder.doc
		{ service, renderer } = nobone()
		Q = require 'q'
		marked = require 'marked'
		marked_html = kit.path.normalize __dirname + '/../assets/markdown/index.html'
		source_html = kit.path.normalize __dirname + '/../assets/markdown/source.html'
		nobone_readme = kit.path.normalize __dirname + '/../readme.md'
		assets_dir = kit.path.normalize __dirname + '/../assets'

		service.get '/', (req, res) ->
			Q.all([
				renderer.render marked_html
				kit.readFile nobone_readme, 'utf8'
			])
			.done (rets) ->
				[tpl, md] = rets
				md = md.replace /\[\!\[NPM.+\)/, ''
				res.send tpl({
					body: marked md
				})

		service.get '/*.coffee', (req, res) ->
			Q.all([
				renderer.render source_html
				kit.readFile req.path[1..], 'utf8'
			])
			.done (rets) ->
				[tpl, source] = rets
				res.send tpl({
					path: req.path
					body: source
				})

		service.use '/assets', renderer.static(assets_dir)

		service.listen 0, ->
			port = service.server.address().port
			kit.log "Listen: " + "#{cmder.host}:#{port}".cyan
			kit.open 'http://127.0.0.1:' + port
			if process.platform != 'darwin' and process.platform != 'win32'
				kit.log ('Visit: http://127.0.0.1:' + port).yellow
		return

	if cmder.args[0]
		fs = require 'fs'
		stats = fs.statSync(cmder.args[0])

		if stats.isFile()
			lib_path = kit.path.normalize "#{__dirname}/../node_modules"
			node_lib_path = kit.path.normalize "#{__dirname}/../../"

			if not process.env.NODE_PATH or process.env.NODE_PATH.indexOf(lib_path) < 0
				path_arr = [lib_path, node_lib_path]
				if process.env.NODE_PATH
					path_arr.push process.env.NODE_PATH
				process.env.NODE_PATH = path_arr.join kit.path.delimiter

				args = process.argv[1..]
				watch_list = args[-1..]
				if cmder.watch
					watch_list = watch_list.concat cmder.watch
				kit.monitor_app {
					args
					watch_list
				}
				return

			require 'coffee-script/register'
			require fs.realpathSync(cmder.args[0])
			return
		else
			cmder.root_dir = cmder.args[0]

	kit.monitor_app {
		args: [
			__dirname + '/static_server.js'
			cmder.host
			cmder.port
			cmder.root_dir
		]
		watch_list: cmder.watch
	}


if not is_action
	init()
