###*
 * Memory cache is faster than direct file streaming even on SSD machine.
 * ```
 * * memory x 1,167 ops/sec ±4.11% (68 runs sampled)
 * * stream x   759 ops/sec ±2.77% (79 runs sampled)
 * ```
###

Q = require 'q'
http = require 'http'
Benchmark = require('benchmark')
suite = new Benchmark.Suite
Benchmark.support.timeout = false

nobone = require '../lib/nobone'
nb = nobone()

port = 8013
file_path = 'readme.md'
s_etag = 0
nb.service.get '/stream', (req, res) ->
	res.set 'Etag', s_etag++
	res.sendfile file_path

nb.service.get '/', (req, res) ->
	res.send 200

fs = require 'fs'
mem_cache = fs.readFileSync file_path
m_etag = 0
nb.service.get '/memory', (req, res) ->
	res.set 'Etag', m_etag++
	res.type 'jpg'
	res.send mem_cache

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

server = nb.service.listen port, ->

	suite

	.add('* memory', {
		defer: true
		fn: (deferred) ->
			get '/memory', port
			.done (data) ->
				deferred.resolve data
	})

	.add('* stream', {
		defer: true
		fn: (deferred) ->
			get '/stream', port
			.done (data) ->
				deferred.resolve data
	})

	.on 'cycle', (e) ->
		console.log e.target.toString()
	.on 'complete', (e) ->
		server.close()
	.run({ 'async': true })
