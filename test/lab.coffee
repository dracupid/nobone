require 'coffee-cache'

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv } = nobone()

{ Promise, _ } = kit

srv.get '/', (req, res) ->
	rr.render 'test/fixtures/index.html'
	.done (tpl_fn) ->
		res.send tpl_fn({ name: 'nobone' })

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
