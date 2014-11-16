###*
 * Covers most important interfaces.
###

assert = require 'assert'
nobone = require '../lib/nobone'
{ kit } = nobone
{ Promise, _ } = kit

nb = nobone {
	db: {}
	renderer: {}
	service: {}
	lang:
		lang_path: 'test/fixtures/lang'
}

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

	nb.service.use nb.renderer.static('test/fixtures')
	nb.service.use '/test', nb.renderer.static('test')

	it 'compiler', (tdone) ->
		port = 8022
		watcher_file_cache = null

		server = nb.service.listen port, ->
			Promise.all([
				get '/main.js', port
				get '/default.css', port
				get '/err_sample.css', port
				get '/bundle.jsb', port
				get '/jade.html', port
				get '/less.css', port
			])
			.then (results) ->
				assert.equal results[0].indexOf("document.body.appendChild(elem);"), 77
				assert.equal results[1].indexOf("color: #319;"), 94
				assert.equal results[2], 'compile_error'
				assert.equal results[3].indexOf('sourceMappingURL'), 814

				assert.equal results[4].indexOf('Nobone'), 44
				assert.equal results[5].indexOf('color: red;'), 58
			.then ->
				nb.kit.readFile 'test/fixtures/deps_root/mixin3.styl'
			.then (str) ->
				# Test the watcher
				watcher_file_cache = str

				compile_p = new Promise (resolve) ->
					nb.renderer.once 'compiled', resolve

				nb.kit.outputFile('test/fixtures/deps_root/mixin3.styl', """
				cor()
					.input3
						color #990
				""").then -> compile_p
			.then ->
				get '/default.css', port
			.then (code) ->
				assert.equal code.indexOf("color: #990;"), 94
				tdone()
			.catch (err) ->
				tdone err.stack
			.then ->
				nb.kit.outputFile 'test/fixtures/deps_root/mixin3.styl', watcher_file_cache
			.done ->
				server.close()

	it 'render force html', (tdone) ->
		nb.kit.glob 'test/fixtures/inde*.ejs'
		.then ([path]) ->
			nb.renderer.render(path, '.html')
		.done (tpl) ->
			assert.equal tpl({ name: 'nobone' }).indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t'), 0
			tdone()

	it 'render raw', (tdone) ->
		nb.kit.glob 'test/fixtures/include.ejs'
		.then ([path]) ->
			nb.renderer.render(path)
		.done (func) ->
			str = func.toString().replace /\r\n/g, '\n'
			assert.equal str.indexOf('include-content'), 77
			tdone()

	it 'render js directly', (tdone) ->
		nb.renderer.render('test/fixtures/test.js')
		.done (str) ->
			assert.equal str, 'var a = 10;'
			tdone()

	it 'renderer with data', (tdone) ->
		{ renderer: rr } = nobone()
		rr.render(
			'test/fixtures/index.html'
			{ name: 'nobone' }
		).done (page) ->
			assert.equal page.indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t<title>nobone</title>'), 0
			tdone()

	it 'database', (tdone) ->
		nb.db.loaded.then ->
			nb.db.exec({
				command: (jdb) ->
					jdb.doc.a = 1
					jdb.save()
			}).then ->
				nb.db.exec({
					command: (jdb) ->
						jdb.send jdb.doc.a
				}).then (d) ->
					assert.equal d, 1
					tdone()
		.done()

	it 'custom code_handler', (tdone) ->
		{ renderer: rr } = nobone {
			renderer: {
				cache_dir: '.nobone/custom_code_handler'
			}
		}

		rr.file_handlers['.js'].compiler = (str) ->
			str[0..3]

		rr.render 'test/fixtures/main.js'
		.done (str) ->
			assert.equal str, 'elem'
			tdone()

	it 'nobone.close', (tdone) ->
		port = 8398
		nb2 = nobone()
		nb2.service.listen port, ->
			nb2.close().done ->
				tdone()

	it 'cli', (tdone) ->
		port = 8223
		ps = nb.kit.spawn('node', [
			'bin/nobone.js'
			'-p', port
			'--no-open-dir'
			'test/fixtures'
		]).process

		get '/main.js', port
		.then (res) ->
			assert.equal res.indexOf("document.body.appendChild(elem);"), 77
			tdone()
		.catch (err) ->
			tdone err.stack
		.done ->
			setTimeout ->
				ps.kill 'SIGINT'
			, 200

describe 'Proxy: ', ->

	it 'url', (tdone) ->
		nb3 = nobone { service: {}, proxy: {} }
		nb3.service.get '/proxy_origin', (req, res) ->
			res.send req.headers

		nb3.service.use '/proxy', (req, res) ->
			nb3.proxy.url req, res, '/proxy_origin'

		nb3.service.listen 8291, ->
			p = get '/proxy', 8291, { client: 'ok' }
			.then (body) ->
				data = JSON.parse body
				assert.equal data.client, 'ok'

				nb3.close()
				tdone()

describe 'Kit:', ->

	it 'kit.parse_comment', (tdone) ->
		path = 'lib/nobone.coffee'
		nb.kit.readFile path, 'utf8'
		.done (str) ->
			comments = nb.kit.parse_comment 'nobone', str, path
			assert.equal comments[1].path, path
			assert.equal comments[1].tags[0].type, 'Object'
			assert.equal comments[1].tags[0].name, 'modules'
			tdone()

	it 'async progress', (tdone) ->
		len = nb.kit.fs.readFileSync(__filename).length
		iter = (i) ->
			if i == 10
				return
			nb.kit.readFile __filename

		nb.kit.async 3, iter, false, (ret) ->
			assert.equal ret.length, len
		.done (rets) ->
			assert.equal rets, undefined
			tdone()

	it 'async results', (tdone) ->
		len = nb.kit.fs.readFileSync(__filename).length

		nb.kit.async(3, _.times 10, ->
			(i) ->
				assert.equal typeof i, 'number'
				nb.kit.readFile __filename
		, (ret) ->
			assert.equal ret.length, len
		).done (rets) ->
			assert.equal rets.length, 10
			tdone()

	it 'lang', ->
		str = nb.lang 'test', 'cn'
		assert.equal str, '测试'
		assert.equal 'test|0'.l, 'test'
		assert.equal 'find %s men'.lang([10], 'cn'), '找到 10 个人'
		assert.equal 'plain'.l, '平面'
		assert.equal 'open|casual'.lang('cn'), '打开'

	it 'crypto', ->
		en = nb.kit.encrypt '123', 'test'
		assert.equal nb.kit.decrypt(en, 'test').toString(), '123'
