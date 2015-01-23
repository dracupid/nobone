cmder = require 'commander'
nobone = require './nobone'
{ kit } = nobone

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


findPlugin = (name) ->
	searchDirs = kit.generateNodeModulePaths(name)[1..]

	searchDirs = searchDirs.concat [
		kit.path.join(nodeLibPath, name)
		kit.path.join(libPath, name)
	]

	paths = kit.fs.globSync searchDirs
	kit._.uniq paths

cmder
	.usage """[action] [options] [rootDir or coffeeFile or jsFile].\
		\n
		    Default rootDir is current folder.

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
				return eval list
			catch
				return [list]
	).option '--no-open-dir', "Disable auto-open the static file site."
	.option '-v, --ver', 'Print version.'
	.option '-d, --doc', 'Open the web documentation.'

cmder
	.command 'ls'
	.description 'List all available nobone plugins.'
	.action ->
		isAction = true

		list = findPlugin('nobone-*').map (path) ->
			conf = require path + '/package'
			name = kit.path.basename(path).replace('nobone-', '').cyan
			ver = ('@' + conf.version).green
			"#{name}#{ver} #{conf.description} [#{path.grey}]"
		console.log """
		\n#{'Available Plugins:'.grey}

		#{list.join('\n\n')}
		"""

cmder.parse process.argv

init = ->
	if cmder.args[0]
		pluginPath = 'nobone-' + cmder.args[0]
		if kit.fs.existsSync cmder.args[0]
			if kit.fs.statSync(cmder.args[0]).isFile()
				return runApp()
			else
				opts.rootDir = cmder.args[0]
		else if (paths = findPlugin(pluginPath); paths.length > 0)
			runApp paths[0]
			return
		else
			kit.err 'Nothing executable: '.red + cmder.args[0]
			return

	if cmder.interactive
		nb = nobone(null, { checkUpgrade: false })
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
		path = require.resolve('./nobone')
		console.log "#{nobone.version()} ".green + "(#{path})".grey
		return

	if cmder.doc
		server = require './docServer'
		opts.port = if cmder.port then cmder.port else 8963
		opts.openDir = cmder.openDir
		server opts
		return

	runDir()

runApp = (plugin) ->
	# Add the above dirs to PATH env.
	if not process.env.NODE_PATH or process.env.NODE_PATH.indexOf(libPath) < 0
		pathArr = [libPath, nodeLibPath]
		if process.env.NODE_PATH
			pathArr.push process.env.NODE_PATH
		process.env.NODE_PATH = pathArr.join kit.path.delimiter

		args = process.argv[1..]
		watchList = cmder.args.filter (el) -> kit.fs.fileExistsSync el
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

runDir = ->
	opts.port = cmder.port if cmder.port

	kit.monitorApp {
		args: [
			__dirname + '/staticServer.js'
			opts.host
			opts.port
			opts.rootDir
			cmder.openDir
		]
		watchList: opts.watch or 'off'
	}


if not isAction
	init()
