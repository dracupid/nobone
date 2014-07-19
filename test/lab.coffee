nobone = require '../lib/nobone'
_ = require 'lodash'


{ kit, renderer: rr, service: srv } = nobone()


kit.request {
	url: 'http://127.0.0.1:8123/'
}
.done (body) ->
	kit.log body.length


s = _.template '<%= "<" + "%= test %" + ">" %>', {}
kit.log s

srv.use rr.static('bone/client')

srv.listen 8013
