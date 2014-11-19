nobone = require './nobone'
marked = require 'marked'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enable_watcher: true
	}
}

{ renderer: assets_r } = nobone {
	renderer:
		enable_watcher: false
		auto_log: false
		cache_dir: kit.path.join __dirname, '/../.nobone/renderer_cache'
}

[ host, port, root_dir, open_dir ] = process.argv[2..]
assets_dir = kit.path.join __dirname, '/../assets'
marked_html =  kit.path.join __dirname, '/../assets/markdown/index.html'
nobone_favicon = kit.path.join __dirname, '/../assets/img/nobone.png'

# Markdown support
renderer.file_handlers['.md'].compiler = (str, path) ->
	md = marked str
	renderer.render marked_html
	.then (tpl) ->
		tpl { path, body: md }

service.get '/favicon.ico', (req, res) ->
	res.sendFile nobone_favicon

service.use renderer.static(root_dir)
service.use '/assets', assets_r.static(assets_dir)
kit.log "Static folder: " + root_dir.cyan

service.listen port, host, ->
	kit.log "Listen: " + "#{host}:#{port}".cyan

	if JSON.parse open_dir
		kit.open 'http://127.0.0.1:' + port
