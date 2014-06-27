require 'coffee-script/register'
fs = require 'fs'
kit = require './lib/kit'

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
			fs.unlink path
