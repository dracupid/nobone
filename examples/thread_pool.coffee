###*
 * This is a example of how to use `kit.async` to deal with producer-consumer problem.
 *
 * Of cause, most time `kit.async` is used with a fixed array, this is a complex
 * usage of it.
###

nobone = require 'nobone'
{ kit } = nobone
{ _, Q } = kit

store = []

# Max running threads at the same time.
max_producer = 5
max_consumer = 2

launch = ->
	kit.async max_producer, producer, false
	kit.async max_consumer, consumer, false

sleep = (time) ->
	defer = Q.defer()

	setTimeout ->
		defer.resolve()
	, time

	defer.promise

producer = ->
	url = 'http://www.baidu.com/s?wd=' + _.random(10 ** 7)
	kit.request url
	.then (page) ->
		store.push page
		kit.log "+ produced: #{url}".grey

		# We don't want to attack the server.
		sleep _.random(1000)
	.catch (err) ->
		kit.err err

consumer = ->
	if store.length > 0
		# Consume an product.
		page = store.pop()
		kit.log "- consume: #{page.length}".green

		# Return a non-undefined value to keep the thread_pool running.
		# If you want to exit this thread pool, return `undefined` will do.
		true
	else
		# Nothing to work, sleep.
		sleep 200

launch()
