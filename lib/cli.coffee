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
	.option '-v, --ver', 'Print version.'

cmder
	.command 'bone <dest_dir>'
	.description 'A guid to create server scaffolding.'
	.option '--pattern <minimatch>', "The file match pattern."
	.action (dest_dir, opts) ->
		is_action = true

		{ kit } = require './nobone'

		kit.generate_bone({
			prompt: [{
				name: 'name'
				description: 'The name of the app:'
				required: true
			}]
			src_dir: kit.path.normalize(__dirname + '/../tpl')
			dest_dir
			pattern: opts.pattern or '**'
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

	nb = require './nobone'

	if cmder.args[0]
		fs = require 'fs'
		stats = fs.statSync(cmder.args[0])
		if stats.isFile()
			lib_path = nb.kit.path.normalize "#{__dirname}/../node_modules"
			node_lib_path = nb.kit.path.normalize "#{__dirname}/../../"
			if not process.env.NODE_PATH or process.env.NODE_PATH.indexOf(lib_path) < 0
				process.env.NODE_PATH += ':' + lib_path + ':' + node_lib_path
				args = process.argv[1..]
				nb.kit.monitor_app {
					args
					watch_list: [args[1]]
				}
				return

			require 'coffee-script/register'
			require fs.realpathSync(cmder.args[0])
			return
		else
			cmder.root_dir = cmder.args[0]

	nb.init {
		service: {}
		renderer: {
			enable_watcher: true
		}
	}

	nb.service.use nb.renderer.static({ root_dir: cmder.root_dir })
	nb.kit.log "Static folder: " + cmder.root_dir.cyan

	nb.renderer.on 'watch_file', (path) ->
		nb.kit.log "Watch: #{path}".cyan

	nb.renderer.on 'file_modified', (path) ->
		nb.kit.log "Modified: #{path}".cyan

	nb.renderer.on 'compile_error', (path, err) ->
		nb.kit.log (path + '\n' + err.toString()).red, 'error'


	nb.service.server.listen cmder.port, cmder.host
	nb.kit.log "Listen: " + "#{cmder.host}:#{cmder.port}".cyan

if not is_action
	init()
