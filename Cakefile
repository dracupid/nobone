require 'coffee-script/register'
try
	kit = require './lib/kit'
catch e
	kit = require './dist/kit'

Q = require 'q'

coffee_bin = 'node_modules/.bin/coffee'
mocha_bin = 'node_modules/.bin/mocha'

task 'dev', 'Run a development server.', ->
	app_path = 'test/usage.coffee'
	kit.monitor_app {
		bin: coffee_bin
		args: [app_path]
		watch_list: [app_path, 'lib/**/*.coffee']
	}

task 'test', 'Basic test', ->
	[
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn(mocha_bin, [
			'-r'
			'coffee-script/register'
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

task 'build', 'Compile coffee to js', ->
	kit.log "Compile coffee..."

	kit.spawn coffee_bin, [
		'-o', 'dist'
		'-cb', 'lib'
	]


task 'clean', 'Clean js', ->
	kit.log ">> Clean js..."

	kit.remove('dist').done()
