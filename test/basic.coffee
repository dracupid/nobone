process.env.NODE_ENV = 'development'

assert = require 'assert'
nobone = require '../lib/nobone'
{ kit } = nobone
{ Promise, _ } = kit

nb = nobone {
	db: {}
	renderer: {}
	service: {}
}, {
	lang_dir: 'test/lang'
}

get = (path, port) ->
	nb.kit.request {
		url: '127.0.0.1'
		port: port
		path: path
	}

describe 'Basic:', ->

	nb.service.use nb.renderer.static('test/fixtures')
	nb.service.use '/test', nb.renderer.static('test')

	nb.renderer.file_handlers['.css'].compiler = (str, path) ->
		@dependency_reg = /@(?:import|require)\s+([^\r\n]+)/
		@dependency_roots = 'test/fixtures/deps_root'

		stylus = nb.kit.require 'stylus'
		c = stylus(str)
			.set('filename', path)
			.include(@dependency_roots)
		Promise.promisify(
			c.render, c
		)()

	port = 8022
	nb.kit.log 'Listen port: ' + port
	watcher_file_cache = null

	it 'compiler', (tdone) ->
		server = nb.service.listen port, ->
			Promise.all([
				get '/main.js', port
				get '/default.css', port
				get '/err_sample.css', port
			])
			.then (results) ->
				assert.equal results[0].indexOf("document.body.appendChild(elem);"), 75
				assert.equal results[1], "h1 {\n  color: #126dd0;\n}\nh1 a {\n  color: #f00;\n}" +
					"\nh1 .input2 {\n  color: #00f;\n}\nh1 .input3 {\n  color: #008000;\n}\n"
				assert.equal results[2], 'compile_error'
			.then ->
				nb.kit.readFile 'test/fixtures/main.coffee'
			.then (str) ->
				watcher_file_cache = str
				# Test the watcher
				nb.kit.outputFile 'test/fixtures/main.coffee', "console.log 'no'"
			.then ->
				new Promise (resolve, reject) ->
					setTimeout(->
						get '/main.js', port
						.catch (err) -> reject err
						.then (code) ->
							resolve code
					, 1000)
			.then (code) ->
				assert.equal code, "console.log('no');\n"
			.then ->
				nb.kit.outputFile 'test/fixtures/main.coffee', watcher_file_cache
			.done ->
				server.close()
				tdone()

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
			assert.equal len, watcher_file_cache.length
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
			'test/fixtures'
		]).process

		setTimeout(->
			get '/main.js', port
			.catch (err) ->
				tdone err.stack
			.then (res) ->
				assert.equal res.indexOf("document.body.appendChild(elem);"), 75
				tdone()
			.fin ->
				ps.kill 'SIGINT'
		, 1000)

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

		nb.kit.async 3, iter, false
		.progress (ret) ->
			assert.equal ret.length, len
		.done (rets) ->
			assert.equal rets, undefined
			tdone()

	it 'async results', (tdone) ->
		len = nb.kit.fs.readFileSync(__filename).length

		nb.kit.async 3, _.times 10, ->
			(i) ->
				assert.equal typeof i, 'number'
				nb.kit.readFile __filename
		.progress (ret) ->
			assert.equal ret.length, len
		.done (rets) ->
			assert.equal rets.length, 10
			tdone()

	it 'lang normal', ->
		str = nb.kit.lang 'test', 'cn'
		assert.equal str, '测试'

	it 'lang alter', ->
		assert.equal 'test|0'.l, 'test'

	it 'crypto', ->
		en = nb.kit.encrypt '123', 'test'
		assert.equal nb.kit.decrypt(en, 'test').toString(), '123'
