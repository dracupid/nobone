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


srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
