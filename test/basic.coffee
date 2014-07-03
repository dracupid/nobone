process.env.NODE_ENV = 'development'

assert = require 'assert'
http = require 'http'
Q = require 'q'
nobone = require '../lib/nobone'

nb = nobone.create {
	db: {}
	renderer: {}
	service: {}
}

get = (path, port) ->
	deferred = Q.defer()

	req = http.request {
		host: '127.0.0.1'
		port: port
		path: path
		method: 'GET'
	}, (res) ->
		data = ''
		res.on 'data', (chunk) ->
			data += chunk

		res.on 'end', ->
			try
				deferred.resolve data
			catch e
				deferred.reject e

	req.end()

	deferred.promise

describe 'Basic:', ->

	nb.service.use nb.renderer.static({ root_dir: 'bone/client' })

	port = 8022
	server = nb.service.listen port
	nb.kit.log 'Listen port: ' + port

	it 'the compiler should work', (tdone) ->

		Q.all([
			get '/main.js', port
			get '/default.css', port
		])
		.then (results) ->
			assert.equal results[0], "var elem;\n\nelem = document.createElement('h1');\n\nelem.textContent = 'Nobone';\n\ndocument.body.appendChild(elem);\n"
			assert.equal results[1], "h1 {\n  color: #126dd0;\n}\n"
		.then ->
			# Test the watcher
			nb.kit.outputFile 'bone/client/main.coffee', "console.log 'no'"
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
			nb.kit.outputFile 'bone/client/main.coffee', """
				elem = document.createElement 'h1'
				elem.textContent = 'Nobone'
				document.body.appendChild elem
			"""
		.done ->
			server.close()
			tdone()

	it 'module_defaults should work', (tdone) ->
		nobone.module_defaults('renderer').done (d) ->
			assert.equal d.code_handlers['.js'].ext_src, '.coffee'
			tdone()

	it 'the render should work', (tdone) ->
		nb.renderer.render('bone/index.ejs')
		.done (tpl) ->
			assert.equal tpl({ body: 'ok' }), '<!DOCTYPE html>\n<html>\n<head>\n\t<title>NoBone</title>\n\t<link rel="stylesheet" type="text/css" href="/default.css">\n</head>\n<body>\n\nok\n<script type="text/javascript" src="/main.js"></script>\n\n</body>\n</html>\n'
			tdone()

	it 'the db should work', (tdone) ->
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

	it 'the custom code_handler should work', (tdone) ->
		{ renderer: rr } = nobone.create()

		rr.code_handlers['.js'].compiler = (str) ->
			str.length

		rr.render 'bone/client/main.coffee'
		.done (len) ->
			assert.equal len, 93
			tdone()

	it 'the close should work.', (tdone) ->
		port = 8398
		nb = nobone.create()
		nb.service.listen port, ->
			nb.close().done ->
				tdone()

	it 'the cli should work', (tdone) ->
		if process.env.no_server_test == 'on'
			tdone()
			return

		port = 8223
		ps = nb.kit.spawn('node', [
			'bin/nobone.js'
			'-p', port
			'bone/client'
		]).process

		setTimeout(->
			get '/default.css', port
			.then (res) ->
				assert.equal res, "h1 {\n  color: #126dd0;\n}\n"
				tdone()
			.fin ->
				ps.kill 'SIGINT'
		, 1000)
