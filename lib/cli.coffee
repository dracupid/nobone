process.env.NODE_ENV = 'development'

cmder = require 'commander'
nobone = require './nobone'
kit = nobone.kit

# These are nobone's dependencies.
lib_path = kit.path.normalize "#{__dirname}/../node_modules"

# These are npm global installed libs.
node_lib_path = kit.path.normalize "#{__dirname}/../../"

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

		    Any package, whether npm installed locally or globally, that is prefixed with 'nobone-'
		    will be treat as a nobone plugin. You can use 'nobone <plugin_name> [args]' to run a plugin.
		    Note that the 'plugin_name' should be without the 'nobone-' prefix.
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

cmder
	.command 'ls'
	.description 'List all available nobone plugins.'
	.action ->
		is_action = true
		paths = []
		kit.glob kit.path.join(node_lib_path, 'nobone-*')
		.then (ps) ->
			paths = paths.concat ps
			kit.glob kit.path.join(lib_path, 'nobone-*')
		.done (ps) ->
			paths = paths.concat ps
			list = paths.map (el) ->
				conf = require el + '/package'
				name = kit.path.basename(el).replace('nobone-', '').cyan
				ver = ('@' + conf.version).grey
				"#{name}#{ver} " + conf.description
			console.log """
			#{'Available Plugins:'.grey}
			#{list.join('\n')}
			"""

cmder.parse process.argv

init = ->
	if cmder.args[0]
		plugin_path = 'nobone-' + cmder.args[0]
		if kit.fs.existsSync cmder.args[0]
			if kit.fs.statSync(cmder.args[0]).isFile()
				return run_an_app()
			else
				opts.root_dir = cmder.args[0]
		else if kit.fs.existsSync(kit.path.join(node_lib_path, plugin_path)) or
		kit.fs.existsSync(kit.path.join(lib_path, plugin_path))
			run_an_app plugin_path
			return
		else
			kit.err 'Nothing executable: '.red + cmder.args[0]
			return

	if cmder.ver
		console.log require('../package').version
		return

	if cmder.doc
		server = require './doc_server'
		opts.port = if cmder.port then cmder.port else 8963
		server opts
		return

	run_a_dir()

run_an_app = (plugin) ->
	# Add the above dirs to PATH env.
	if not process.env.NODE_PATH or process.env.NODE_PATH.indexOf(lib_path) < 0
		path_arr = [lib_path, node_lib_path]
		if process.env.NODE_PATH
			path_arr.push process.env.NODE_PATH
		process.env.NODE_PATH = path_arr.join kit.path.delimiter

		args = process.argv[1..]
		watch_list = args[1..].filter (el) -> kit.fs.existsSync el
		if cmder.watch
			watch_list = watch_list.concat cmder.watch
		kit.monitor_app {
			args
			watch_list
		}
	else
		require 'coffee-script/register'
		if plugin
			require plugin
		else
			require kit.fs.realpathSync(cmder.args[0])

run_a_dir = ->
	opts.port = cmder.port if cmder.port

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
