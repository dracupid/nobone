process.env.NODE_ENV = 'development'

assert = require 'assert'
Q = require 'q'
_ = require 'lodash'
nobone = require '../lib/nobone'

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

	nb.service.use nb.renderer.static('test/test_app')
	nb.service.use '/test', nb.renderer.static('test')

	port = 8022
	nb.kit.log 'Listen port: ' + port
	watcher_file_cache = null

	it 'compiler', (tdone) ->
		server = nb.service.listen port, ->
			Q.all([
				get '/main.js', port
				get '/default.css', port
				get '/test/err_sample.css', port
			])
			.then (results) ->
				assert.equal results[0].indexOf("document.body.appendChild(elem);"), 75
				assert.equal results[1], "h1 {\n  color: #126dd0;\n}\n"
				assert.equal results[2], 'compile_error'
			.then ->
				nb.kit.readFile 'test/test_app/main.coffee'
			.then (str) ->
				watcher_file_cache = str
				# Test the watcher
				nb.kit.outputFile 'test/test_app/main.coffee', "console.log 'no'"
			.then ->
				deferred = Q.defer()
				setTimeout(->
					get '/main.js', port
					.catch (err) -> deferred.reject err
					.then (code) ->
						deferred.resolve code
				, 1000)
				deferred.promise
			.then (code) ->
				assert.equal code, "console.log('no');\n"
			.then ->
				nb.kit.outputFile 'test/test_app/main.coffee', watcher_file_cache
			.done ->
				server.close()
				tdone()

	it 'module_defaults', (tdone) ->
		nobone.module_defaults('renderer').done (d) ->
			assert.equal d.file_handlers['.js'].ext_src, '.coffee'
			tdone()

	it 'render', (tdone) ->
		nb.renderer.render('test/test_app/index.ejs')
		.done (tpl) ->
			assert.equal tpl({ name: 'nobone' }).indexOf('<!DOCTYPE html>\n<html>\n<head>\n\t'), 0
			tdone()

	it 'renderer with data', (tdone) ->
		{ renderer: rr } = nobone()
		rr.render(
			'test/test_app/index.ejs'
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

	it 'custom code_handler', (tdone) ->
		{ renderer: rr } = nobone()

		rr.file_handlers['.js'].compiler = (str) ->
			str.length

		rr.render 'test/test_app/main.coffee'
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
		if process.env.no_server_test == 'on'
			tdone()
			return

		port = 8223
		ps = nb.kit.spawn('node', [
			'bin/nobone.js'
			'-p', port
			'test/test_app'
		]).process

		setTimeout(->
			get '/default.css', port
			.then (res) ->
				assert.equal res, "h1 {\n  color: #126dd0;\n}\n"
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
