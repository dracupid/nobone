process.env.NODE_ENV = 'production'

nobone = require './nobone'
{ kit, service, renderer } = nobone()

noboneDir = kit.path.join __dirname, '..'

service.get '/', (req, res) ->
	res.redirect '/readme.md?offline'

service.use renderer.staticEx({
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
