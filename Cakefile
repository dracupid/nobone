process.env.NODE_ENV = 'development'
process.chdir __dirname

kit = require './lib/kit'
{ Promise, _ } = kit

build = require './build'

option '-d', '--debug', 'Node debug mode'
option '-p', '--port [port]', 'Node debug mode'

task 'dev', 'Dev Server', (opts) ->
	app_path = 'test/lab.coffee'
	if opts.debug
		port = opts.port or 8283
		args = ['--nodejs', '--debug-brk=' + port, app_path]
	else
		args = [app_path]

	kit.monitor_app {
		bin: 'coffee'
		args
		watch_list: ['test/lab.coffee', 'lib/**/*.coffee']
	}

task 'test', 'Basic test', (options) ->
	build()
	.then ->
		kit.remove '.nobone'
	.then ->
		[
			'test/basic.coffee'
		].forEach (file) ->
			kit.spawn('mocha', [
				'-t', 30 * 1000
				'-r', 'coffee-script/register'
				'-R', 'spec'
				file
			]).process.on 'exit', (code) ->
				if code != 0
					process.exit code
	.done()

task 'build', 'Compile coffee and Docs', ->
	build()

task 'clean', 'Clean js', ->
	kit.log ">> Clean js..."

	kit.remove('dist').done()

task 'hotfix', 'Hotfix third dependencies\' bugs', ->
	# ys: Node break again and again.

task 'benchmark', 'Some basic benchmarks', ->
	server = kit.spawn('coffee', ['benchmark/load_test_server.coffee'])

	setTimeout ->
		tester = kit.spawn('coffee', ['benchmark/mem_vs_stream.coffee'])
		tester.done ->
			server.process.kill "SIGINT"
	, 500

