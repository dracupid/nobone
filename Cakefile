process.env.NODE_ENV = 'development'

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
	build().then ->
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

# Just for fun.
task 'code', 'Code Statistics of this project', ->
	line_count = 0
	size_count = 0

	kit.glob [
		'assets', 'benchmark', 'bin', 'bone', 'doc', 'examples', 'lib', 'test'
	].map (el) -> el + '/**/*.+(js|coffee|styl|css|md|ejs|html)'
	.then (paths) ->
		paths.push 'Cakefile'

		kit.log ' File Count: '.cyan + paths.length

		kit.async 20, (i) ->
			if i >= paths.length
				return
			Promise.all [
				kit.readFile paths[i], 'utf8'
				kit.stat paths[i]
			]
		, false, ([str, stats]) ->
			line_count += str.split('\n').length
			size_count += stats.size
	.done ->
		kit.log 'Total Lines: '.cyan + line_count
		kit.log ' Total Size: '.cyan + (size_count / 1024).toFixed(2) + ' kb'

task 'hotfix', 'Hotfix third dependencies\' bugs', ->
	# ys: Node break again and again.

task 'benchmark', 'Some basic benchmarks', ->
	server = kit.spawn('coffee', ['benchmark/load_test_server.coffee'])

	setTimeout ->
		tester = kit.spawn('coffee', ['benchmark/mem_vs_stream.coffee'])
		tester.done ->
			server.process.kill "SIGINT"
	, 500

