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
	.usage '[action] [options] [root_dir or coffee_file or js_file]. Default root_dir is current folder.'
	.option '-p, --port <port>', "Server port. Default is #{defaults.port}.", (d) -> +d
	.option '--host <host>', "Host to listen to. Default is #{defaults.host} only."
	.option '-w, --watch <list>', "Watch list to auto-restart server. String or JSON array.", (list) ->
		try
			return JSON.parse list
		catch
			return [list]
	.option '-v, --ver', 'Print version.'

cmder
	.command 'bone <dest_dir>'
	.description 'A guid to create server scaffolding.'
	.option '--pattern <minimatch>', "The file match pattern."
	.action (dest_dir, opts) ->
		is_action = true

		nobone = require './nobone'

		{ kit, renderer } = nobone()

		kit.generate_bone({
			prompt: [{
				name: 'name'
				description: 'The name of the app:'
				required: true
			}]
			src_dir: kit.path.normalize(__dirname + '/../bone')
			dest_dir
			pattern: opts.pattern or '**'
			compile: (str, data, path) ->
				ejs = kit.require 'ejs'
				data.filename = path
				data.body = renderer.auto_reload()
				ejs.render str, data
		})
		.catch (err) ->
			if err.message == 'canceled'
				kit.log 'Canceled'.yellow
			else
				throw err
		.done()

cmder.parse process.argv

init = ->
	if cmder.ver
		console.log require('../package').version
		return

	_.defaults cmder, defaults

	nobone = require './nobone'
	kit = nobone.kit

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
