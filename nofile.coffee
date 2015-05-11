kit = require 'nokit'
{ _, Promise, warp } = kit
drives = kit.require 'drives'

module.exports = (task, option) ->

	option '-d, --debug', 'node debug mode'
	option '-p, --port [8283]', 'node debug mode', 8283

	task 'default', ['build', 'test'], true

	task 'lab l', 'run and monitor "test/lab.coffee"', (opts) ->
		args = ['test/lab.coffee']

		if opts.debug
			args.splice 0, 0, '--nodejs', '--debug-brk=' + opts.port

		kit.monitorApp { bin: 'coffee', args }

	option '-g, --grep ["."]', 'test pattern', '.'
	option '-t, --timeout [3000]', 'test timeout', 3000
	task 'test t', 'run unit tests', (opts) ->
		kit.spawn('mocha', [
			'-t', opts.timeout
			'-r', 'coffee-script/register'
			'-R', 'spec'
			'-g', opts.grep
			'test/basic.coffee'
		])
		.catch (err) ->
			if err.code
				process.exit err.code
			else
				Promise.reject err

	option '-a, --all', 'rebuild all without cache'
	task 'build b', ['clean'], 'build project', (opts) ->
		compile = kit.async [
			warp 'lib/**/*.coffee'
				.load drives.auto 'lint'
				.load drives.auto 'compile'
				.run 'dist'
			warp 'assets/**/*.{coffee,styl}'
				.load drives.auto 'compile'
				.run 'assets'
		]

		buildDocs = Promise.all [
				'doc/faq.md'
				'examples/basic.coffee'
			].map (path) ->
				kit.readFile path, 'utf8'
			.then (rets) ->
				kit.glob 'examples/*.coffee'
				.then (paths) ->
					rets.push paths.sort().map(
						(l) -> "- [#{kit.path.basename(l, '.coffee')}](#{l}?source)"
					).join('\n')
					rets
			.then ([faq, basic, examples]) ->
				warp 'lib/**/*.coffee'
				.load drives.comment2md
					doc: { faq, basic, examples }
					h: 4, tpl: 'doc/readme.jst.md'
				.run()

		kit.async [compile, buildDocs]

	task 'clean', 'clean js', (opts) ->
		list = [
			'.nobone'
			'dist'
			'assets/**/*.css'
		]
		if opts.all
			list.push '.nokit'
		kit.async list.map _.ary kit.remove, 1

	task 'hotfix', 'hotfix third dependencies\' bugs', ->
		# ys: Node break again and again.

	task 'benchmark', 'run some basic benchmarks', ->
		{ process: server } = kit.spawn 'coffee', ['benchmark/load_test_server.coffee']

		setTimeout ->
			kit.spawn 'coffee', ['benchmark/mem_vs_stream.coffee']
			.catch(->).then ->
				server.process.kill "SIGINT"
		, 500

