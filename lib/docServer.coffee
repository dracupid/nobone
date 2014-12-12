process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()

noboneDir = kit.path.join __dirname, '..'

service.get '/', (req, res) ->
	res.redirect '/readme.md?offlineMarkdown'

service.get '/nobone-doc/*', (req, res, next) ->
	reqPath = '/'
	if req.headers.referer
		reqPath = kit.url
			.parse(req.headers.referer).pathname
			.replace(/\/[^\/]+$/, '/')

	paths = kit.generateNodeModulePaths(
		req.params[0].replace('/', kit.path.sep)
		kit.path.join noboneDir, reqPath
	)

	for path in paths
		if kit.fs.existsSync path
			url = kit.path
				.relative(noboneDir, path)
				.replace(kit.path.sep, '/')
			res.redirect '/' + url + '?offlineMarkdown'
			return
	next()

service.use renderer.staticEx({
	rootDir: noboneDir
	index: true
})

service.get '/favicon.ico', (req, res) ->
	noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'
	res.sendFile noboneFavicon

module.exports = (opts) ->
	service.listen opts.port, ->
		port = service.server.address().port
		kit.log "Listen: " + "#{opts.host}:#{port}".cyan
		kit.open 'http://127.0.0.1:' + port
		.catch(->)
