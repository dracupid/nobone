process.env.NODE_ENV = 'development'

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv } = nobone()

srv.use rr.static('bone/client')

srv.listen 8013
