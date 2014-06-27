process.env.NODE_ENV = 'development'

assert = require 'assert'
http = require 'http'
Q = require 'q'
nb = require '../lib/nobone'

port = 8022

get = (path) ->
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

describe 'basic test', ->

	nb.service.use nb.renderer.assets({ root_dir: 'test' })

	server = nb.service.listen port
	nb._.log 'Listen port: ' + port

	it 'the compiler should work', (tdone) ->

		Q.all([
			get '/sample.js'
			get '/sample.css'
		])
		.then (results) ->
			assert.equal results[0], "console.log('ok');\n"
			assert.equal results[1], "a h1 {\n  background: #000;\n}\n"
		.done ->
			server.close()
			tdone()

	it 'the render should work', (tdone) ->
		nb.renderer.render('test/sample.ejs')
		.done (tpl) ->
			assert.equal tpl({ OK: 'ok' }), 'ok'
			tdone()
