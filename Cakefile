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
	list = [
		'test/basic.coffee'
	]

	list.map (file) ->
		kit.spawn('node_modules/.bin/mocha', [
			'-r'
			'coffee-script/register'
			file
		], { stdio: 'inherit' }).process
		.on 'exit', (code) ->
			if code != 0
				process.exit code


task 'build', 'Compile coffee to js', ->
	console.log "Compile coffee..."

	kit.spawn 'node_modules/.bin/coffee', [
		'-cb'
		'lib'
	], {
		stdio: 'inherit'
	}


task 'clean', 'Clean js', ->
	console.log ">> Clean js..."

	kit.glob('lib/**/*.js').done (paths) ->
		for path in paths
			kit.remove path
