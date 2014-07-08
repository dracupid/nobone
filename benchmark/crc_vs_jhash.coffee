###*
 * As we can see, jhash is about 1.6x faster than crc32.
 * crc file x 5,930 ops/sec ±0.25% (100 runs sampled)
 * crc str x 73,916 ops/sec ±0.34% (100 runs sampled)
 * jhash file x 9,675 ops/sec ±0.43% (98 runs sampled)
 * jhash str x 121,068 ops/sec ±1.42% (98 runs sampled)
###

Benchmark = require('benchmark')
suite = new Benchmark.Suite
Benchmark.support.timeout = false
fs = require 'fs'

util = require '../node_modules/express/lib/utils.js'
jhash = require 'jhash'

file = fs.readFileSync 'assets/img/nobone.png'
str = fs.readFileSync 'assets/markdown/github.styl'

suite

.add('* crc file', {
	fn: ->
		util.wetag file
})

.add('* crc str', {
	fn: ->
		util.wetag str
})

.add('* jhash file', {
	fn: () ->
		jhash.hash file
})

.add('* jhash str', {
	fn: () ->
		jhash.hash str
})

.on 'cycle', (e) ->
	console.log e.target.toString()
.on 'complete', (e) ->
	console.log 'done'
.run({ 'async': true })
