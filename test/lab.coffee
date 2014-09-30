nobone = require '../lib/nobone'
_ = require 'lodash'

{ kit, renderer: rr, service: srv } = nobone()

rr.file_handlers['.css'].compiler = (str, path) ->
	@dependency_reg = /@(?:import|require)\s+([^\r\n]+)/
	@dependency_roots = 'test/fixtures/deps_root'

	stylus = kit.require 'stylus'
	c = stylus(str)
		.set('filename', path)
		.include(@dependency_roots)

	kit.Promise.promisify(
		c.render, c
	)()

srv.get '/', (req, res) ->
	rr.render 'test/fixtures/index.html'
	.done (tpl_fn) ->
		res.send tpl_fn({ name: 'nobone' })

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
