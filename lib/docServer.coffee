process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()
{ Promise } = kit
marked = require 'marked'

noboneDir = kit.path.normalize __dirname + '/../'
markedHtml = kit.path.normalize __dirname + '/../assets/markdown/index.html'
sourceHtml = kit.path.normalize __dirname + '/../assets/markdown/source.html'
noboneReadme = kit.path.normalize __dirname + '/../readme.md'
noboneFavicon = kit.path.normalize __dirname + '/../assets/img/nobone.png'

docCache = null
service.get '/', (req, res) ->
	if docCache != null
		return res.send docCache

	Promise.all([
		renderer.render markedHtml
		kit.readFile noboneReadme, 'utf8'
	])
	.done (rets) ->
		[tpl, md] = rets
		md = md.replace /\[\!\[NPM.+\)/, ''
		links = []
		md = md.replace /\s+(\[.+?\]:.+?\n)/g, (m, p) ->
			links.push p
			return ''
		md += '\n' + links.join('')
		docCache = tpl({
			body: marked md
		})
		res.send docCache

service.get '/*.coffee', (req, res, next) ->
	path = kit.path.normalize __dirname + '/../' + req.path[1..]
	Promise.all([
		renderer.render sourceHtml
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
	rootDir: noboneDir
	index: true
})
service.get '/favicon.ico', (req, res) ->
	res.sendFile noboneFavicon

module.exports = (opts) ->
	service.listen opts.port, ->
		port = service.server.address().port
		kit.log "Listen: " + "#{opts.host}:#{port}".cyan
		kit.open 'http://127.0.0.1:' + port
		if process.platform != 'darwin' and process.platform != 'win32'
			kit.log ('Visit: http://127.0.0.1:' + port).yellow
