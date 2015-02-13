###*
 * Covers most important interfaces.
###

assert = require 'assert'
nobone = require '../lib/nobone'
http = require 'http'
net = require 'net'
{ kit } = nobone
{ Promise, _ } = kit


shouldEqual = (args...) ->
	try
		assert.strictEqual.apply assert, args
	catch err
		Promise.reject err

shouldDeepEqual = (args...) ->
	try
		assert.deepEqual.apply assert, args
	catch err
		Promise.reject err

get = (path, port, headers) ->
	wait = (span = 100) ->
		new Promise (resolve) ->
			setTimeout ->
				resolve()
			, span

	kit.request {
		url: '127.0.0.1'
		port: port
		path: path
		redirect: 3
		headers
	}
	.catch (err) ->
		if err.code == 'ECONNREFUSED'
			wait().then ->
				get path, port
		else
			Promise.reject err

serverList = []

freePort = ->
	server = net.createServer()

	new Promise (resolve) ->
		server.listen 0, ->
			{ port } = server.address()

			server.close ->
				resolve port

describe 'Basic:', ->
	after ->
		for s in serverList
			try s.close()

	it 'render main.coffee', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		serverList.push server = service.listen 0, ->
			{ port } = server.address()
			get '/main.js', port
			.then (body) ->
				assert.equal body.indexOf("document.body.appendChild(elem);"), 77
				tdone()

	it 'render errSample.styl', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		server = service.listen 0, ->
			{ port } = server.address()
			get '/errSample.css', port
			.then (body) ->
				assert.equal body, 'compileError'

				server.close ->
					tdone()
			.catch (err) ->
				server.close ->
					tdone err.stack or err

	it 'render 打包.coffee', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		server = service.listen 0, ->
			{ port } = server.address()
			get '/' + encodeURIComponent('打包.jsb'), port
			.then (body) ->
				assert.equal body.indexOf('sourceMappingURL'), 812

				server.close ->
					tdone()
			.catch (err) ->
				server.close ->
					tdone err.stack or err

	it 'render jade.jade', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		server = service.listen 0, ->
			{ port } = server.address()
			get '/jade.html', port
			.then (body) ->
				assert.equal body.indexOf('Nobone'), 78

				server.close ->
					tdone()
			.catch (err) ->
				server.close ->
					tdone err.stack or err

	it 'render less.less', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		server = service.listen 0, ->
			{ port } = server.address()
			get '/less.css', port
			.then (body) ->
				assert.equal body.indexOf('color: red;'), 58

				server.close ->
					tdone()
			.catch (err) ->
				server.close ->
					tdone err.stack or err

	it 'renderer watch', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		watcherFileCache = null

		server = service.listen 0, ->
			{ port } = server.address()

			final = ->
				kit.outputFile 'test/fixtures/depsRoot/mixin3.styl', watcherFileCache
				.then ->
					kit.promisify(server.close, server)()

			watched = new Promise (resolve) ->
				renderer.once 'watchFile', resolve

			get '/default.css', port
			.then ->
				kit.readFile 'test/fixtures/depsRoot/mixin3.styl'
			.then (str) ->
				# Test the watcher
				watcherFileCache = str
				watched
			.then ->
				compiled = new Promise (resolve) ->
					renderer.once 'compiled', resolve

				kit.outputFile('test/fixtures/depsRoot/mixin3.styl', """
				cor()
					.input3
						color #990
				""")

				compiled
			.then ->
				get '/default.css', port
			.then (code) ->
				assert.equal code.indexOf("color: #990;"), 94
				final()
			.then ->
				tdone()
			.catch (err) ->
				final().then ->
					tdone err.stack or err

	it 'render force html', ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/inde*.ejs'
		.then ([path]) ->
			renderer.render(path, '.html')
		.then (tpl) ->
			shouldEqual(
				tpl({ name: 'nobone' }).indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t'), 0
			)

	it 'render tpl', ->
		{ renderer } = nobone { renderer: {} }

		renderer.render 'test/fixtures/tpl.html'
		.then (fn) ->
			shouldEqual(
				fn({ name: 'nobone' }).indexOf('nobone') > 0, true
			)

	it 'render raw', ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/include.ejs'
		.then ([path]) ->
			renderer.render(path)
		.then (func) ->
			str = func.toString().replace /\r\n/g, '\n'
			shouldEqual str.indexOf('include-content'), 77

	it 'render js directly', ->
		{ renderer } = nobone { renderer: {} }

		renderer.render('test/fixtures/test.js')
		.then (str) ->
			shouldEqual str, 'var a = 10;'

	it 'renderer with data', ->
		{ renderer: rr } = nobone()

		rr.render(
			'test/fixtures/index.html'
			{ name: 'nobone' }
		).then (page) ->
			shouldEqual(
				page.indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t<title>nobone</title>'), 0
			)

	it 'database', ->
		{ db } = nobone { db: { dbPath: '.nobone/db_test.db' } }

		db.loaded.then ->
			db.exec({
				command: (jdb) ->
					jdb.doc.a = 1
					jdb.save()
			}).then ->
				db.exec({
					command: (jdb) ->
						jdb.send jdb.doc.a
				}).then (d) ->
					shouldEqual d, 1

	it 'custom codeHandler', ->
		{ renderer: rr } = nobone {
			renderer: {
				cacheDir: '.nobone/customCodeHandler'
			}
		}

		rr.fileHandlers['.js'].compiler = (str) ->
			str[0..3]

		rr.render 'test/fixtures/main.js'
		.then (str) ->
			shouldEqual str, 'elem'

	it 'nobone.close', ->
		nbInstance = nobone { service: {} }
		{ service } = nbInstance
		service.listen 0, ->
			nbInstance.close()

	it 'cli', (tdone) ->
		freePort().then (port) ->
			ps = kit.spawn('node', [
				'bin/nobone.js'
				'-p', port
				'--no-open-dir'
				'test/fixtures'
			]).process

			get '/main.js', port
			.then (res) ->
				assert.equal res.indexOf("document.body.appendChild(elem);"), 77
				setTimeout ->
					ps.kill 'SIGINT'
					tdone()
				, 200
			.catch (err) ->
				ps.kill 'SIGINT'
				tdone err.stack

	it 'cli dir', (tdone) ->
		freePort().then (port) ->
			ps = kit.spawn('node', [
				'bin/nobone.js'
				'-p', port
				'--no-open-dir'
				'test/fixtures'
			]).process

			get '/', port
			.then (res) ->
				pos = res.indexOf("<body>")
				assert.equal pos > 0, true
				setTimeout ->
					ps.kill 'SIGINT'
					tdone()
				, 200
			.catch (err) ->
				ps.kill 'SIGINT'
				tdone err.stack

	it 'cli doc', (tdone) ->
		os = require 'os'
		freePort().then (port) ->
			ps = kit.spawn('node', [
				kit.path.join __dirname, '..', 'bin', 'nobone.js'
				'-p', port
				'--no-open-dir'
				'--doc'
			], {
				cwd: os.tmpDir()
			}).process

			get '/', port
			.then (res) ->
				assert.equal res.indexOf("<body>") > 0, true
				setTimeout ->
					ps.kill 'SIGINT'
					tdone()
				, 200
			.catch (err) ->
				ps.kill 'SIGINT'
				setTimeout ->
					ps.kill 'SIGINT'
					tdone err.stack
				, 200

	it 'lang', ->
		{ lang } = nobone { lang: { langPath: 'test/fixtures/lang' } }

		str = lang 'test', 'cn'
		assert.equal str, '测试'
		assert.equal 'test|0'.l, 'test'
		assert.equal 'find %s men'.lang([10], 'cn'), '找到 10 个人'
		assert.equal 'plain'.l, '平面'
		assert.equal 'open|casual'.lang('cn'), '打开'

describe 'Proxy: ', ->

	it 'url', (tdone) ->
		require 'url'

		nbInstance = nobone { proxy: {} }

		server = http.createServer (req, res) ->
			{ path } = kit.url.parse(req.url)
			if path == '/proxyOrigin'
				res.end JSON.stringify(req.headers)

			if path == '/proxy'
				nbInstance.proxy.url req, res, '/proxyOrigin', {
					bps: 30 * 1024
				}

		server.listen 0, ->
			{ port } = server.address()
			get '/proxy', port, { client: 'ok' }
			.then (body) ->
				data = JSON.parse body
				assert.equal data.client, 'ok'
				tdone()
			.catch tdone
