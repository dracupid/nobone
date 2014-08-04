require 'coffee-script/register'
Q = require 'q'
nobone = require 'nobone'
{ kit } = nobone

task 'dev', 'dev server', ->
	kit.monitor_app {
		bin: 'coffee'
		args: ['app.coffee']
	}

task 'setup', 'setup', ->
	Q.fcall ->
		kit.log 'Setup bower...'
		kit.spawn 'bower', ['install']
	.then ->
		kit.fileExists 'conf.coffee'
	.then (exists) ->
		if not exists
			kit.copy 'lib/conf.example.coffee', 'conf.coffee'
	.then ->
		kit.log 'Setup done.'
	.done()

task 'test', 'test', (options) ->
	[
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn('mocha', [
			'-r', 'coffee-script/register'
			'-R', 'spec'
			file
		]).process.on 'exit', (code) ->
			if code != 0
				process.exit code
