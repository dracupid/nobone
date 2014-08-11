nobone = require '../lib/nobone'
_ = require 'lodash'


{ kit, renderer: rr, service: srv } = nobone()

# s = _.template '<%= "<" + "%= test %" + ">" %>', {}
# kit.log s

# srv.use rr.static('bone/client')

kit.readFile 'lib/kit.coffee', 'utf8'
.done (str) ->
	arr = kit.parse_comment('kit', str)
	el = arr.filter((el) -> el.name == 'request')[0]
	kit.log el.tags[1].description

# srv.listen 8013
