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
		headers
	}
	.catch (err) ->
		if err.code == 'ECONNREFUSED'
			wait().then ->
				get path, port
		else
			Promise.reject err

describe 'Basic:', ->

	it 'compiler', (tdone) ->
		{ service, renderer } = nobone { service: {}, renderer: {} }

		service.use renderer.static('test/fixtures')
		service.use '/test', renderer.static('test')

		server = service.listen 0, ->
			{ port } = server.address()
			Promise.all([
				get '/main.js', port
				get '/errSample.css', port
				get '/' + encodeURIComponent('打包.jsb'), port
				get '/jade.html', port
				get '/less.css', port
			])
			.then (results) ->
				assert.equal results[0].indexOf("document.body.appendChild(elem);"), 77
				assert.equal results[1], 'compileError'
				assert.equal results[2].indexOf('sourceMappingURL'), 812
				assert.equal results[3].indexOf('Nobone'), 44
				assert.equal results[4].indexOf('color: red;'), 58
				tdone()
			.catch (err) ->
				tdone err.stack or err
			.then ->
				server.close()

	it 'render force html', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/inde*.ejs'
		.then ([path]) ->
			renderer.render(path, '.html')
		.done (tpl) ->
			assert.equal(
				tpl({ name: 'nobone' }).indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t'), 0
			)
			tdone()

	it 'render raw', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		kit.glob 'test/fixtures/include.ejs'
		.then ([path]) ->
			renderer.render(path)
		.done (func) ->
			str = func.toString().replace /\r\n/g, '\n'
			assert.equal str.indexOf('include-content'), 77
			tdone()

	it 'render js directly', (tdone) ->
		{ renderer } = nobone { renderer: {} }

		renderer.render('test/fixtures/test.js')
		.done (str) ->
			assert.equal str, 'var a = 10;'
			tdone()

	it 'renderer with data', (tdone) ->
		{ renderer: rr } = nobone()

		rr.render(
			'test/fixtures/index.html'
			{ name: 'nobone' }
		).done (page) ->
			assert.equal(
				page.indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t<title>nobone</title>'), 0
			)
			tdone()

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
		.done()

	it 'custom codeHandler', (tdone) ->
		{ renderer: rr } = nobone {
			renderer: {
				cacheDir: '.nobone/customCodeHandler'
			}
		}

		rr.fileHandlers['.js'].compiler = (str) ->
			str[0..3]

		rr.render 'test/fixtures/main.js'
		.done (str) ->
			assert.equal str, 'elem'
			tdone()

	it 'nobone.close', (tdone) ->
		port = 8398
		nbInstance = nobone { service: {} }
		{ service } = nbInstance
		service.listen port, ->
			nbInstance.close().done ->
				tdone()

	it 'cli', (tdone) ->
		port = 8223
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
			tdone err.stack
		.done()

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
		nb3 = nobone { service: {}, proxy: {} }
		nb3.service.get '/proxyOrigin', (req, res) ->
			res.send req.headers

		nb3.service.use '/proxy', (req, res) ->
			nb3.proxy.url req, res, '/proxyOrigin'

		nb3.service.listen 8291, ->
			p = get '/proxy', 8291, { client: 'ok' }
			.then (body) ->
				data = JSON.parse body
				assert.equal data.client, 'ok'

				nb3.close()
				tdone()
