process.env.NODE_ENV = 'development'

nobone = require './nobone'
marked = require 'marked'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enableWatcher: true
	}
}

[ host, port, rootDir, openDir ] = process.argv[2..]

# Markdown support
renderer.fileHandlers['.md'].compiler = (str, path) ->
	markedHtml =  kit.path.join __dirname, '/../assets/markdown/index.html'
	md = marked str
	renderer.render markedHtml
	.then (tpl) ->
		tpl { path, body: md }

# Favicon.
service.get '/favicon.ico', (req, res) ->
	noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'
	res.sendFile noboneFavicon

service.use renderer.static(rootDir)
kit.log "Static folder: " + rootDir.cyan

service.listen port, host, ->
	kit.log "Listen: " + "#{host}:#{port}".cyan

	if JSON.parse openDir
		kit.open 'http://127.0.0.1:' + port
