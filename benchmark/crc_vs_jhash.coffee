###*
 * As we can see, jhash is about 1.5x faster than crc32.
 * And the results collision test are nearly the same.
 * ```
 * Performance Test
 * crc buffer   x 5,903 ops/sec ±0.52% (100 runs sampled)
 * crc str      x 54,045 ops/sec ±6.67% (83 runs sampled)
 * jhash buffer x 9,756 ops/sec ±0.67% (101 runs sampled)
 * jhash str    x 72,056 ops/sec ±0.36% (94 runs sampled)
 *
 * Collision Test
 * ***** jhash *****
 *   5 samples: 3481292839,1601668515,957061576,1031084327,1000054056
 *       time: 10.001s
 * collisions: 0.0018788163457017504% (4/212900)
 * ***** crc32 *****
 *   5 samples: 3494480258,2736329845,2815219153,3510180228,2016919691
 *       time: 10.003s
 * collisions: 0.0027945971122544933% (6/214700)
 * ```
###

_ = require 'lodash'
Benchmark = require('benchmark')
suite = new Benchmark.Suite
Benchmark.support.timeout = false
fs = require 'fs'

crc32 = require '../node_modules/express/node_modules/buffer-crc32'
jhash = require 'jhash'

performance_test = ->
	console.log 'Performance Test'

	file = fs.readFileSync 'assets/img/nobone.png'
	str = fs.readFileSync 'assets/markdown/github.styl', 'utf8'

	suite

	.add('crc buffer', {
		fn: ->
			crc32.unsigned file
	})

	.add('crc str', {
		fn: ->
			crc32.unsigned str
	})

	.add('jhash buffer', {
		fn: ->
			jhash.hash file, true
	})

	.add('jhash str', {
		fn: ->
			jhash.hash str, true
	})

	.on 'cycle', (e) ->
		console.log e.target.toString()
	.run({ 'async': true })

collision_test = ->
	console.log 'Collision Test'

	hash = (mod, hash_fun) ->
		arr = []
		for i in [0 ... 1000]
			arr.push _.random(0, 2 ** 8)

		hash_fun.call mod, arr, true

	batch = (mod, hash_fun, name) ->
		start_time = Date.now()
		count = 0
		res = {}
		samples = []
		while true
			v = hash(mod, hash_fun)
			samples.push v
			res[v] = true

			# Run about 10 seconds.
			if ++count % 100 == 0 and
			Date.now() - start_time >= 1000 * 10
				break

		time = (Date.now() - start_time) / 1000
		ratio = (1 - _.size(res) / count) * 100

		console.log """
			***** #{name} *****
			  5 samples: #{samples[0...5]}
			      time: #{time}s
			collisions: #{ratio}% (#{count - _.size(res)}/#{count})
		"""

	batch jhash, jhash.hash, 'jhash'
	batch crc32, crc32.unsigned, 'crc32'

performance_test()
collision_test()
