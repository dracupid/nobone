process.env.NODE_ENV = 'development'

nobone = require './nobone'
marked = require 'marked'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enableWatcher: true
	}
}

{ renderer: assetsR } = nobone {
	renderer:
		enableWatcher: false
		autoLog: false
		cacheDir: kit.path.join __dirname, '/../.nobone/rendererCache'
}

[ host, port, rootDir, openDir ] = process.argv[2..]
assetsDir = kit.path.join __dirname, '/../assets'
markedHtml =  kit.path.join __dirname, '/../assets/markdown/index.html'
noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'

# Markdown support
renderer.fileHandlers['.md'].compiler = (str, path) ->
	md = marked str
	renderer.render markedHtml
	.then (tpl) ->
		tpl { path, body: md }

service.get '/favicon.ico', (req, res) ->
	res.sendFile noboneFavicon

service.use renderer.static(rootDir)
service.use '/assets', assetsR.static(assetsDir)
kit.log "Static folder: " + rootDir.cyan

service.listen port, host, ->
	kit.log "Listen: " + "#{host}:#{port}".cyan

	if JSON.parse openDir
		kit.open 'http://127.0.0.1:' + port
