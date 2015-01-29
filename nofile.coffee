process.chdir __dirname

build = require './build'

option '-d, --debug', 'node debug mode'
option '-p, --port [8283]', 'node debug mode', 8283
option '-b, --bare', 'build source code without doc or lint'

task 'default', ['build'], 'default task is "build"'

task 'dev', 'run and monitor "test/lab.coffee"', (opts) ->
	appPath = 'test/lab.coffee'
	if opts.debug
		port = opts.port
		args = ['--nodejs', '--debug-brk=' + port, appPath]
	else
		args = [appPath]

	kit.monitorApp {
		bin: 'coffee'
		args
	}

option '-g, --grep ["."]', 'test pattern', '.'
task 'test', 'run unit tests', (opts) ->
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
				'-g', opts.grep
				file
			]).catch ({ code }) ->
				process.exit code
	.catch (err) ->
		kit.err err.stack
		process.exit 1

task 'build', 'compile coffee and docs', (opts) ->
	build opts

task 'clean', 'clean js', ->
	kit.log ">> Clean js & css..."

	kit.glob('assets/**/*.css')
	.then (list) ->
		for path in list
			kit.remove path

	kit.remove('dist')

task 'hotfix', 'hotfix third dependencies\' bugs', ->
	# ys: Node break again and again.

task 'benchmark', 'run some basic benchmarks', ->
	{ process: server } = kit.spawn 'coffee', ['benchmark/load_test_server.coffee']

	setTimeout ->
		kit.spawn 'coffee', ['benchmark/mem_vs_stream.coffee']
		.catch(->).then ->
			server.process.kill "SIGINT"
	, 500

