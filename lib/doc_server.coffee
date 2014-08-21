process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()
Q = require 'q'
marked = require 'marked'
marked_html = kit.path.normalize __dirname + '/../assets/markdown/index.html'
source_html = kit.path.normalize __dirname + '/../assets/markdown/source.html'
nobone_readme = kit.path.normalize __dirname + '/../readme.md'
assets_dir = kit.path.normalize __dirname + '/../assets'
nobone_favicon = kit.path.normalize __dirname + '/../assets/img/nobone.png'

doc_cache = null
service.get '/', (req, res) ->
	if doc_cache != null
		return res.send doc_cache

	Q.all([
		renderer.render marked_html
		kit.readFile nobone_readme, 'utf8'
	])
	.done (rets) ->
		[tpl, md] = rets
		md = md.replace /\[\!\[NPM.+\)/, ''
		links = []
		md = md.replace /\s+(\[.+?\]:.+?\n)/g, (m, p) ->
			links.push p
			return ''
		md += '\n' + links.join('')
		doc_cache = tpl({
			body: marked md
		})
		res.send doc_cache

service.get '/*.coffee', (req, res) ->
	path = kit.path.normalize __dirname + '/../' + req.path[1..]
	Q.all([
		renderer.render source_html
		kit.readFile path, 'utf8'
	])
	.done (rets) ->
		[tpl, source] = rets
		res.send tpl({
			path: req.path
			body: source
		})

service.use '/assets', renderer.static(assets_dir)
service.get '/favicon.ico', (req, res) ->
	res.sendfile nobone_favicon

module.exports = (opts) ->
	service.listen opts.port, ->
		port = service.server.address().port
		kit.log "Listen: " + "#{opts.host}:#{port}".cyan
		kit.open 'http://127.0.0.1:' + port
		if process.platform != 'darwin' and process.platform != 'win32'
			kit.log ('Visit: http://127.0.0.1:' + port).yellow
