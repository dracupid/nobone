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

task 'dev', 'Dev Server', ->
	kit.monitor_app {
		bin: 'coffee'
		args: ['test/lab.coffee']
		watch_list: ['test/lab.coffee', 'lib/**/*.coffee']
	}

task 'test', 'Basic test', (options) ->
	if options['no-server']
		process.env.no_server_test = 'on'

	[
		# 'test/single.coffee'
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn(mocha_bin, [
			'-r', 'coffee-script/register'
			'-R', 'spec'
			file
		]).process.on 'exit', (code) ->
			if code != 0
				process.exit code

task 'build', 'Compile coffee to js', build = ->
	kit.log "Compile coffee..."

	kit.spawn coffee_bin, [
		'-o', 'dist'
		'-cb', 'lib'
	]

	# Build readme
	kit.log 'Make readme...'
	Q.all([
		kit.readFile 'doc/faq.md', 'utf8'
		kit.readFile 'doc/readme.ejs.md', 'utf8'
		kit.readFile 'examples/usage.coffee', 'utf8'
		kit.readFile 'benchmark/mem_vs_stream.coffee', 'utf8'
		kit.readFile 'benchmark/crc_vs_jhash.coffee', 'utf8'
	]).then (rets) ->
		faq = rets[0]
		usage = rets[2]
		{
			tpl: rets[1]
			usage
			faq
			mods: [
				'lib/nobone.coffee'
				'lib/modules/service.coffee'
				'lib/modules/renderer.coffee'
				'lib/modules/db.coffee'
				'lib/modules/proxy.coffee'
				'lib/kit.coffee'
			]
			benchmark: kit.parse_comment 'benchmark', rets[3] + rets[4]
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
