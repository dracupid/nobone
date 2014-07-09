###*
 * As we can see, jhash is about 1.5x faster than crc32.
 * Their results of collision test are nearly the same.
 * ```
 * Performance Test
 * crc buffer   x 5,903 ops/sec ±0.52% (100 runs sampled)
 * crc str      x 54,045 ops/sec ±6.67% (83 runs sampled)
 * jhash buffer x 9,756 ops/sec ±0.67% (101 runs sampled)
 * jhash str    x 72,056 ops/sec ±0.36% (94 runs sampled)
 *
 * === Collision Test ===
 * ***** jhash *****
 * time: 10.002s
 * collisions: 0.004007480630510286% (15 / 374300)
 * ***** crc32 *****
 * time: 10.001s
 * collisions: 0.004445855827246745% (14 / 314900)
 * ```
###

_ = require 'lodash'
Benchmark = require('benchmark')
crypto = require 'crypto'
suite = new Benchmark.Suite
Benchmark.support.timeout = false
fs = require 'fs'

crc32 = require '../node_modules/express/node_modules/buffer-crc32'
jhash = require 'jhash'

file = fs.readFileSync 'assets/img/nobone.png'
str = fs.readFileSync 'readme.md', 'utf8'

performance_test = ->
	console.log '=== Performance Test ==='

	suite

	.add('  crc buffer', {
		fn: ->
			crc32.unsigned file
	})

	.add('jhash buffer', {
		fn: ->
			jhash.hash file, true
	})

	.add('  crc str', {
		fn: ->
			buf = new Buffer str
			crc32.unsigned buf
	})

	.add('jhash str', {
		fn: ->
			jhash.hash str, true
	})

	.on 'cycle', (e) ->
		console.log e.target.toString()
	.run({ 'async': true })

collision_test = ->
	console.log '\n=== Collision Test ==='

	hash = (mod, hash_fun) ->
		arr = []
		for i in [0 ... 500]
			arr[i] = _.random(0, 2 ** 8 - 1)

		buf = new Buffer(arr)

		md5_sum = crypto
			.createHash('md5')
			.update(buf)
			.digest('base64')

		[
			hash_fun.call mod, arr, true
			md5_sum
		]

	batch = (mod, hash_fun, name) ->
		start_time = Date.now()
		count = 0
		collision = 0
		res = {}
		while true
			v = hash(mod, hash_fun)
			if res[v[0]] and res[v[0]] != v[1]
				collision++
			else
				res[v[0]] = v[1]

			# Run about 10 seconds.
			if ++count % 100 == 0 and
			Date.now() - start_time >= 1000 * 10
				break

		time = (Date.now() - start_time) / 1000

		console.log """
			***** #{name} *****
			time: #{time}s
			collisions: #{collision / count * 100}% (#{collision} / #{count})
		"""

	batch jhash, jhash.hash, 'jhash'
	batch crc32, crc32.unsigned, 'crc32'

performance_test()
collision_test()
