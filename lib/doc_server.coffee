process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()
{ Promise } = kit
marked = require 'marked'

nobone_dir = kit.path.normalize __dirname + '/../'
marked_html = kit.path.normalize __dirname + '/../assets/markdown/index.html'
source_html = kit.path.normalize __dirname + '/../assets/markdown/source.html'
nobone_readme = kit.path.normalize __dirname + '/../readme.md'
nobone_favicon = kit.path.normalize __dirname + '/../assets/img/nobone.png'

doc_cache = null
service.get '/', (req, res) ->
	if doc_cache != null
		return res.send doc_cache

	Promise.all([
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

service.get '/*.coffee', (req, res, next) ->
	path = kit.path.normalize __dirname + '/../' + req.path[1..]
	Promise.all([
		renderer.render source_html
		kit.readFile path, 'utf8'
	])
	.then (rets) ->
		[tpl, source] = rets
		res.send tpl({
			path: req.path
			body: source
		})
	.catch ->
		next()

service.use renderer.static({
	root_dir: nobone_dir
	index: true
})
service.get '/favicon.ico', (req, res) ->
	res.sendFile nobone_favicon

module.exports = (opts) ->
	service.listen opts.port, ->
		port = service.server.address().port
		kit.log "Listen: " + "#{opts.host}:#{port}".cyan
		kit.open 'http://127.0.0.1:' + port
		if process.platform != 'darwin' and process.platform != 'win32'
			kit.log ('Visit: http://127.0.0.1:' + port).yellow
