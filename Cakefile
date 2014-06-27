require 'coffee-script/register'
kit = require './lib/kit'

task 'dev', 'Run a development server.', ->
	app_path = 'test/usage.coffee'
	ps = null
	# Redirect process io to stdio.
	start = ->
		ps = kit.spawn('coffee', [
			app_path
		], kit.env_mode 'development').process

	start()

	kit.watch_files [app_path, 'lib/*.coffee'], (path, curr, prev) ->
		if curr.mtime != prev.mtime
			console.log "\n\n>> Reload Server: ".yellow + path
			ps.kill 'SIGINT'
			start()

task 'test', 'Basic test', ->
	list = [
		'test/basic.coffee'
	]

	list.map (file) ->
		kit.spawn('mocha', [
			'-r'
			'coffee-script/register'
			file
		], { stdio: 'inherit' }).process
		.on 'exit', (code) ->
			if code != 0
				process.exit code


task 'build', 'Compile coffee to js', ->
	console.log "Compile coffee..."

	kit.spawn 'coffee', [
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
