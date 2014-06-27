require 'coffee-script/register'
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
