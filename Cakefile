require 'coffee-script/register'
_ = require 'lodash'
try
	kit = require './lib/kit'
catch e
	kit = require './dist/kit'

Q = require 'q'

coffee_bin = 'node_modules/.bin/coffee'
mocha_bin = 'node_modules/.bin/mocha'

option '-n', '--no-server', 'Test without standalone test'

task 'dev', 'Run a development server.', ->
	app_path = 'test/usage.coffee'
	kit.monitor_app {
		bin: coffee_bin
		args: [app_path]
		watch_list: [app_path, 'lib/**/*.coffee']
	}

task 'test', 'Basic test', (options) ->
	if options['no-server']
		process.env.no_server_test = 'on'

	[
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn(mocha_bin, [
			'-r', 'coffee-script/register'
			'-R', 'spec'
			file
		]).process.on 'exit', (code) ->
			if code != 0
				process.exit code

task 'setup', 'Setup project.', ->
	socketio_index_path = 'node_modules/socket.io/lib/index.js'
	Q.fcall ->
		kit.log "Fix socket.io etag bug.".cyan
		kit.readFile socketio_index_path, 'utf8'
	.then (str) ->
		str = str.replace 'req.headers.etag', 'req.headers["if-none-match"]'
		kit.outputFile socketio_index_path, str
	.done ->
		kit.log 'Setup finished.'.yellow

task 'build', 'Compile coffee to js', build = ->
	kit.log "Compile coffee..."

	kit.spawn coffee_bin, [
		'-o', 'dist'
		'-cb', 'lib'
	]

	# Build readme
	kit.log 'Make readme...'
	Q.all([
		kit.readFile 'doc/readme.ejs.md', 'utf8'
		kit.readFile 'test/usage.coffee', 'utf8'
		kit.glob 'lib/modules/*.coffee'
		kit.readFile 'benchmark/mem_vs_stream.coffee', 'utf8'
	]).then (rets) ->
		usage = rets[1].replace "nobone = require '../lib/nobone'", "nobone = require 'nobone'"
		{
			tpl: rets[0]
			usage
			mods: rets[2].concat [
				'lib/kit.coffee'
				'lib/nobone.coffee'
			]
			benchmark: kit.parse_comment 'benchmark', rets[3]
		}
	.then (data) ->
		Q.all data.mods.map (path) ->
			name = kit.path.basename path, '.coffee'
			kit.readFile path, 'utf8'
			.then (code) ->
				kit.parse_comment name, code, path
		.then (rets) ->
			data.mods = _.groupBy _.flatten(rets, true), (el) -> el.module
			data
	.then (data) ->
		ejs = require 'ejs'
		data._ = _

		out = ejs.render data.tpl, data

		kit.outputFile 'readme.md', out

	.done()

task 'clean', 'Clean js', ->
	kit.log ">> Clean js..."

	kit.remove('dist').done()
