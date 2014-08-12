nobone = require '../lib/nobone'
_ = require 'lodash'

{ kit, renderer: rr, service: srv } = nobone()

srv.get '/', (req, res) ->
	rr.render 'test/test_app/index.html'
	.done (tpl) ->
		res.send tpl({ name: '' })

srv.use rr.static('test/test_app')

srv.listen 8013
