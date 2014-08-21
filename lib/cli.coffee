process.env.NODE_ENV = 'development'

_ = require 'lodash'
cmder = require 'commander'

is_action = false

opts = {
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
	.option '-p, --port <port>', "Server port. Default is #{opts.port}.", (d) -> +d
	.option '--host <host>', "Host to listen to. Default is #{opts.host} only."
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
	.action (dest_dir) ->
		is_action = true
		bone = require './bone'
		bone dest_dir

cmder.parse process.argv

init = ->
	if cmder.ver
		console.log require('../package').version
		return

	if cmder.doc
		server = require './doc_server'
		opts.port = if cmder.port then cmder.port else 0
		server opts
		return

	nobone = require './nobone'
	kit = nobone.kit

	if cmder.args[0]
		stats = kit.fs.statSync(cmder.args[0])

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
			require kit.fs.realpathSync(cmder.args[0])
			return
		else
			opts.root_dir = cmder.args[0]

	kit.monitor_app {
		args: [
			__dirname + '/static_server.js'
			opts.host
			opts.port
			opts.root_dir
		]
		watch_list: opts.watch
	}


if not is_action
	init()
