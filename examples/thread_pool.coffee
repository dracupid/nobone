###*
 * This is a example of how to use `kit.async` to deal with producer-consumer problem.
 *
 * Of cause, most time `kit.async` is used with a fixed array, this is a complex
 * usage of it.
###

nobone = require 'nobone'
{ kit } = nobone
{ _, Promise } = kit

tasks = ['http://www.baidu.com']
store = []

# Max running threads at the same time.
max_producer = 5
max_consumer = 2

launch = ->
	# The producer and the comsumer will create
	# a nearly infinity life circle.
	kit.async [
		kit.async max_producer, producer, false
		kit.async max_consumer, consumer, false
	]
	.catch (err) ->
		kit.err err.message

sleep_awhile = ->
	new Promise (resolve) ->
		setTimeout resolve, 200

# Producer will download a page and add it to the store.
producer = ->
	if tasks.length == 0
		# Nothing to work, sleep.
		return sleep_awhile()

	url = tasks.pop()

	kit.request(url).then (page) ->
		kit.log "Produce: #{url}".cyan

		store.push page

# Comsumer will parse a page and find some urls in the page,
# then add the urls to the tasks.
consumer = ->
	if store.length == 0
		return sleep_awhile()

	page = store.pop()

	urls = []

	# Find url in page.
	page.replace /<a[\w\s]+href="(http.+?)"/g, (m, p) ->
		urls.push p

	# Randomly get 3 urls.
	urls = _.sample(urls, 3)

	tasks = tasks.concat urls

launch()
