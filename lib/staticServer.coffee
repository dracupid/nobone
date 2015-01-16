process.env.NODE_ENV = 'development'

nobone = require './nobone'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enableWatcher: true
	}
}

[ host, port, rootDir, openDir ] = process.argv[2..]

service.use renderer.staticEx(rootDir)
kit.log "Static folder: " + rootDir.cyan

# Favicon.
service.get '/favicon.ico', (req, res) ->
	noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'
	res.sendFile noboneFavicon

service.listen port, host, ->
	kit.log "Listen: " + "#{host}:#{port}".cyan

	if JSON.parse openDir
		kit.xopen 'http://127.0.0.1:' + port
		.catch(->)
