process.env.NODE_ENV = 'development'
process.chdir __dirname

kit = require './lib/kit'
{ Promise, _ } = kit

build = require './build'

option '-d', '--debug', 'Node debug mode.'
option '-p', '--port [port]', 'Node debug mode.'
option '-b', '--bare', 'Build source code without doc or lint.'

task 'dev', 'Dev Server', (opts) ->
	appPath = 'test/lab.coffee'
	if opts.debug
		port = opts.port or 8283
		args = ['--nodejs', '--debug-brk=' + port, appPath]
	else
		args = [appPath]

	kit.monitorApp {
		bin: 'coffee'
		args
		watchList: ['test/lab.coffee', 'lib/**/*.coffee']
	}

task 'test', 'Basic test', (opts) ->
	build opts
	.then ->
		kit.remove '.nobone'
	.then ->
		[
			'test/basic.coffee'
		].forEach (file) ->
			kit.spawn('mocha', [
				'-t', 10000
				'-r', 'coffee-script/register'
				'-R', 'spec'
				file
			]).process.on 'exit', (code) ->
				if code != 0
					process.exit code
	.done()

task 'build', 'Compile coffee and Docs', (opts) ->
	build opts

task 'clean', 'Clean js', ->
	kit.log ">> Clean js & css..."

	kit.glob('assets/**/*.css')
	.then (list) ->
		for path in list
			kit.remove path

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

