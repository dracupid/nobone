###*
 * Test burst requests.
###

require 'coffee-cache'
assert = require 'assert'

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv } = nobone()

{ Promise, _ } = kit

count = 0
rr.on 'compiled', (c, handler) ->
	# Under burst requests, async compiler should only be called once.
	assert.equal count++, 0

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	# Attack
	kit.async [
		kit.request 'http://127.0.0.1:8122/default.css'
		kit.request 'http://127.0.0.1:8122/default.css'
		kit.request 'http://127.0.0.1:8122/default.css'
		kit.request 'http://127.0.0.1:8122/default.css'
	]
	.then (res) ->
		assert.equal res[0], res[1]
		kit.log 'Done'.green
