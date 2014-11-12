require 'coffee-cache'

nobone = require '../lib/nobone'

{ kit, renderer: rr, service: srv } = nobone()

{ Promise, _ } = kit

_.extend rr.file_handlers['.css'], {
	dependency_reg: /@(?:import|require)\s+([^\r\n]+)/
	dependency_roots: ['test/fixtures/deps_root']
	compiler: _.wrap rr.file_handlers['.css'].compiler, (fn, str, path) ->
		if @ext == '.styl'
			stylus = kit.require 'stylus'
			c = stylus(str)
				.set('filename', path)
				.set('sourcemap', { inline: true })
				.include(@dependency_roots[0])
			Promise.promisify(
				c.render, c
			)()
		else
			fn.call @, str, path
}

srv.get '/', (req, res) ->
	rr.render 'test/fixtures/index.html'
	.done (tpl_fn) ->
		res.send tpl_fn({ name: 'nobone' })

srv.use rr.static('test/fixtures')

srv.listen 8122, ->
	kit.log 'http://127.0.0.1:8122'
