###*
 * This file is used for testing new features.
###

require 'coffee-cache'

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv, lang } = nobone({
	renderer: {}
	service: {}
	lang: {
		lang_path: 'test/fixtures/lang'
		current: 'cn'
	}
})

{ Promise, _ } = kit

srv.get '/', (req, res) ->
	rr.render 'test/fixtures/index.html'
	.done (tpl_fn) ->
		res.send tpl_fn({ name: 'test'.l })

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
