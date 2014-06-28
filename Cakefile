require 'coffee-script/register'
kit = require './lib/kit'

task 'dev', 'Run a development server.', ->
	app_path = 'test/usage.coffee'
	kit.monitor_app {
		bin: 'coffee'
		app: app_path
		watch_list: [app_path, 'lib/*.coffee']
	}

task 'test', 'Basic test', ->
	[
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn('node_modules/.bin/mocha', [
			'-r'
			'coffee-script/register'
			file
		]).process.on 'exit', (code) ->
			if code != 0
				process.exit code

task 'build', 'Compile coffee to js', ->
	kit.log "Compile coffee..."

	kit.spawn 'node_modules/.bin/coffee', [
		'-o', 'dist'
		'-cb', 'lib'
	]


task 'clean', 'Clean js', ->
	kit.log ">> Clean js..."

	kit.remove('dist').done()
