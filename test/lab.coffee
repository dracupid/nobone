###*
 * This file is used for testing new features.
###

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv, lang } = nobone({
	renderer: {}
	service: {}
	lang: {
		langPath: 'test/fixtures/lang'
		current: 'cn'
	}
})

{ Promise, _ } = kit

srv.get '/', (req, res) ->
	rr.render 'test/fixtures/index.html'
	.then (tplFn) ->
		res.send tplFn({ name: 'test'.l })

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
