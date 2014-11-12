assert = require 'assert'
nobone = require '../lib/nobone'
{ kit } = nobone
{ Promise, _ } = kit

nb = nobone {
	db: {}
	renderer: {}
	service: {}
}, {
	lang_path: 'test/fixtures/lang'
}

wait = (span = 100) ->
	new Promise (resolve) ->
		setTimeout ->
			resolve()
		, span

get = (path, port, headers) ->
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

	_.extend nb.renderer.file_handlers['.css'], {
		dependency_reg: /@(?:import|require)\s+([^\r\n]+)/
		dependency_roots: ['test/fixtures/deps_root']
		compiler: _.wrap nb.renderer.file_handlers['.css'].compiler, (fn, str, path) ->
			if @ext == '.styl'
				stylus = nb.kit.require 'stylus'
				c = stylus(str)
					.set('filename', path)
					.include(@dependency_roots[0])
				Promise.promisify(
					c.render, c
				)()
			else
				fn.call @, str, path
	}

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
				assert.equal results[0].indexOf("document.body.appendChild(elem);"), 75
				assert.equal results[1], """
				h1 {
				  color: #126dd0;
				}
				h1 a {
				  color: #f00;
				}
				h1 .input2 {
				  color: #00f;
				}
				h1 .input3 {
				  color: #008000;
				}\n"""
				assert.equal results[2], 'compile_error'
				assert.equal results[3].indexOf('sourceMappingURL'), 814

				assert.equal results[4].indexOf('<html><head><title></title></head><body><h1>Nobone</h1></body></html>'), 0
				assert.equal results[5], "a b {\n  color: red;\n}\n"
			.then ->
				nb.kit.readFile 'test/fixtures/deps_root/mixin3.styl'
			.then (str) ->
				watcher_file_cache = str
				# Test the watcher
				nb.kit.outputFile 'test/fixtures/deps_root/mixin3.styl', """
				cor()
					.input3
						color yellow
				"""
			.then ->
				wait 1000
			.then ->
				get '/default.css', port
			.then (code) ->
				assert.equal code, """
				h1 {
				  color: #126dd0;
				}
				h1 a {
				  color: #f00;
				}
				h1 .input2 {
				  color: #00f;
				}
				h1 .input3 {
				  color: #ff0;
				}\n"""
			.then ->
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
		{ renderer: rr } = nobone()

		rr.file_handlers['.js'].compiler = (str) ->
			str.length

		rr.render 'test/fixtures/main.js'
		.done (len) ->
			assert.equal len, 90
			tdone()

	it 'nobone.close', (tdone) ->
		port = 8398
		nb = nobone()
		nb.service.listen port, ->
			nb.close().done ->
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
			assert.equal res.indexOf("document.body.appendChild(elem);"), 75
			tdone()
		.catch (err) ->
			tdone err.stack
		.done ->
			ps.kill 'SIGINT'

describe 'Proxy: ', ->
	it 'url', (tdone) ->
		nb = nobone { service: {}, proxy: {} }
		nb.service.get '/proxy_origin', (req, res) ->
			res.send req.headers

		nb.service.use '/proxy', (req, res) ->
			nb.proxy.url req, res, '/proxy_origin'

		nb.service.listen 8291, ->
			p = get '/proxy', 8291, { client: 'ok' }
			.then (body) ->
				data = JSON.parse body
				assert.equal data.client, 'ok'

				nb.close()
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
		str = nb.kit.lang 'test', 'cn'
		assert.equal str, '测试'
		assert.equal 'test|0'.l, 'test'
		assert.equal 'find %s men'.lang([10], 'cn'), '找到 10 个人'
		assert.equal 'plain'.l, '平面'
		assert.equal 'open|casual'.lang('cn'), '打开'

	it 'crypto', ->
		en = nb.kit.encrypt '123', 'test'
		assert.equal nb.kit.decrypt(en, 'test').toString(), '123'
