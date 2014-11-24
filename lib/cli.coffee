process.env.NODE_ENV = 'development'

cmder = require 'commander'
nobone = require './nobone'
kit = nobone.kit

# These are nobone's dependencies.
libPath = kit.path.normalize "#{__dirname}/../node_modules"

# These are npm global installed libs.
nodeLibPath = kit.path.normalize "#{__dirname}/../../"

isAction = false

opts = {
	port: 8013
	host: '0.0.0.0'
	rootDir: './'
}

cmder
	.usage """[action] [options] [rootDir or coffeeFile or jsFile].\
		\n
		    Default rootDir is current folder.
		    For the js or coffee entrance file, you could require any npm lib in
		    nobone's dependencies, You can use "var _ = require('lodash')"
		    without "npm install lodash" before.

		    Any package, whether npm installed locally or globally, that is
		    prefixed with 'nobone-' will be treat as a nobone plugin. You can
		    use 'nobone <pluginName> [args]' to run a plugin.
		    Note that the 'pluginName' should be without the 'nobone-' prefix.
	"""
	.option(
		'-p, --port <port>', "Server port. Default is #{opts.port}."
		(d) -> +d
	).option '--host <host>', "Host to listen to. Default is #{opts.host} only."
	.option '-i, --interactive', "Start as interactive mode."
	.option(
		'-w, --watch <list>'
		"Watch list to auto-restart server.\
		String or JSON array. If 'off', nothing will be watched."
		(list) ->
			try
				return JSON.parse list
			catch
				return [list]
	).option '--no-open-dir', "Disable auto-open the static file site."
	.option '-v, --ver', 'Print version.'
	.option '-d, --doc', 'Open the web documentation.'

cmder
	.command 'bone <destDir>'
	.description 'A guid to create server scaffolding.'
	.action (destDir) ->
		isAction = true
		bone = require './bone'
		bone destDir

cmder
	.command 'ls'
	.description 'List all available nobone plugins.'
	.action ->
		isAction = true
		paths = []
		kit.glob kit.path.join(nodeLibPath, 'nobone-*')
		.then (ps) ->
			paths = paths.concat ps
			kit.glob kit.path.join(libPath, 'nobone-*')
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
		pluginPath = 'nobone-' + cmder.args[0]
		if kit.fs.existsSync cmder.args[0]
			if kit.fs.statSync(cmder.args[0]).isFile()
				return runAnApp()
			else
				opts.rootDir = cmder.args[0]
		else if kit.fs.existsSync(kit.path.join(nodeLibPath, pluginPath)) or
		kit.fs.existsSync(kit.path.join(libPath, pluginPath))
			runAnApp pluginPath
			return
		else
			kit.err 'Nothing executable: '.red + cmder.args[0]
			return

	if cmder.interactive
		nb = nobone()
		kit._.extend global, nb
		kit._.extend global, {
			nobone
			_: kit._
			Promise: kit.Promise
		}

		cmd = require 'coffee-script/lib/coffee-script/command'
		cmd.run()
		return

	if cmder.ver
		console.log require('../package').version
		return

	if cmder.doc
		server = require './docServer'
		opts.port = if cmder.port then cmder.port else 8963
		server opts
		return

	runAndir()

runAnApp = (plugin) ->
	# Add the above dirs to PATH env.
	if not process.env.NODE_PATH or process.env.NODE_PATH.indexOf(libPath) < 0
		pathArr = [libPath, nodeLibPath]
		if process.env.NODE_PATH
			pathArr.push process.env.NODE_PATH
		process.env.NODE_PATH = pathArr.join kit.path.delimiter

		args = process.argv[1..]
		watchList = args[1..].filter (el) -> kit.fs.existsSync el
		if cmder.watch
			watchList = cmder.watch
		kit.monitorApp {
			args
			watchList
		}
	else
		require 'coffee-script/register'
		if plugin
			require plugin
		else
			require kit.fs.realpathSync(cmder.args[0])

runAndir = ->
	opts.port = cmder.port if cmder.port

	kit.monitorApp {
		args: [
			__dirname + '/staticServer.js'
			opts.host
			opts.port
			opts.rootDir
			cmder.openDir
		]
		watchList: opts.watch
	}


if not isAction
	init()
