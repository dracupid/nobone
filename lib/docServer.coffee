process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()

noboneDir = kit.path.join __dirname, '..'

service.get '/', (req, res) ->
	res.redirect '/readme.md?offlineMarkdown'

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
