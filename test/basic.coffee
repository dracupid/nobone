###*
 * Covers most important interfaces.
###

assert = require 'assert'
nobone = require '../lib/nobone'
{ kit } = nobone
{ Promise, _ } = kit

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

freePort = ->
	net = kit.require 'net'
	server = net.createServer()

	new Promise (resolve) ->
		server.listen 0, ->
			{ port } = server.address()

			server.close ->
				resolve port

describe 'Basic:', ->

	it 'render main.coffee', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')

		server = service.listen 0, ->
			{ port } = server.address()
			get '/main.js', port
			.then (body) ->
				assert.equal body.indexOf("document.body.appendChild(elem);"), 77

				server.close ->
					tdone()
			.catch (err) ->
				server.close ->
					tdone err.stack or err

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
				assert.equal body.indexOf('Nobone'), 44

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

	it 'render force html', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/inde*.ejs'
		.then ([path]) ->
			renderer.render(path, '.html')
		.then (tpl) ->
			assert.equal(
				tpl({ name: 'nobone' }).indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t'), 0
			)
			tdone()
		.catch tdone

	it 'render tpl', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		renderer.render 'test/fixtures/tpl.html'
		.then (fn) ->
			assert.equal(
				fn({ name: 'nobone' }).indexOf('nobone') > 0, true
			)
			tdone()
		.catch tdone

	it 'render raw', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/include.ejs'
		.then ([path]) ->
			renderer.render(path)
		.then (func) ->
			str = func.toString().replace /\r\n/g, '\n'
			assert.equal str.indexOf('include-content'), 77
			tdone()
		.catch tdone

	it 'render js directly', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		renderer.render('test/fixtures/test.js')
		.then (str) ->
			assert.equal str, 'var a = 10;'
			tdone()
		.catch tdone

	it 'renderer with data', (tdone) ->
		{ renderer: rr } = nobone()

		rr.render(
			'test/fixtures/index.html'
			{ name: 'nobone' }
		).then (page) ->
			assert.equal(
				page.indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t<title>nobone</title>'), 0
			)
			tdone()
		.catch tdone

	it 'database', (tdone) ->
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
					assert.equal d, 1
					tdone()

	it 'custom codeHandler', (tdone) ->
		{ renderer: rr } = nobone {
			renderer: {
				cacheDir: '.nobone/customCodeHandler'
			}
		}

		rr.fileHandlers['.js'].compiler = (str) ->
			str[0..3]

		rr.render 'test/fixtures/main.js'
		.then (str) ->
			assert.equal str, 'elem'
			tdone()
		.catch tdone

	it 'nobone.close', (tdone) ->
		nbInstance = nobone { service: {} }
		{ service } = nbInstance
		service.listen 0, ->
			nbInstance.close()
			.then ->
				tdone()
			.catch tdone

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
				assert.equal res.indexOf("<body>") > 0, true
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
				cwd: os.tmpdir()
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
		nbInstance = nobone { service: {}, proxy: {} }
		nbInstance.service.get '/proxyOrigin', (req, res) ->
			res.send req.headers

		nbInstance.service.use '/proxy', (req, res) ->
			nbInstance.proxy.url req, res, '/proxyOrigin'

		nbInstance.service.listen 8291, ->
			p = get '/proxy', 8291, { client: 'ok' }
			.then (body) ->
				data = JSON.parse body
				assert.equal data.client, 'ok'

				nbInstance.close()
				tdone()
