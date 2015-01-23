###*
 * <h3>Memory vs Stream</h3>
 * Memory cache is faster than direct file streaming even on SSD machine.
 * It's hard to test the real condition, because most of the file system
 * will cache a file into memory if it being read lot of times.
 *
 * Type   | Performance
 * ------ | ---------------
 * memory | 1,225 ops/sec ±3.42% (74 runs sampled)
 * stream | 933 ops/sec ±3.23% (71 runs sampled)
###

Benchmark = require('benchmark')
suite = new Benchmark.Suite
Benchmark.support.timeout = false

nobone = require '../lib/nobone'
{ kit } = nobone

port = 8215

get = (path, port, defer) ->
	kit.request "http://127.0.0.1:#{port}/#{path}"
	.then (data) ->
		defer.resolve data
	.catch (err) ->
		defer.reject err

suite

.add('* memory', {
	defer: true
	fn: (deferred) ->
		get '/memory', port, deferred
})

.add('* stream', {
	defer: true
	fn: (deferred) ->
		get '/stream', port, deferred
})

.on 'cycle', (e) ->
	console.log e.target.toString()
.run()
