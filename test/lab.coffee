nobone = require '../lib/nobone'
_ = require 'lodash'


{ kit, renderer: rr, service: srv } = nobone()


s = _.template '<%= "<" + "%= test %" + ">" %>', {}
kit.log s

srv.use rr.static('bone/client')

srv.listen 8013
