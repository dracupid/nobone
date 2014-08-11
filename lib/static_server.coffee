nobone = require './nobone'
marked = require 'marked'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enable_watcher: true
	}
}

[ host, port, root_dir ] = process.argv[2..]
assets_dir = kit.path.normalize __dirname + '/../assets'
marked_html =  kit.path.normalize __dirname + '/../assets/markdown/index.html'
nobone_favicon = kit.path.normalize __dirname + '/../assets/img/nobone.png'

# Markdown support
renderer.file_handlers['.md'].compiler = (str, path) ->
	md = marked str
	renderer.render marked_html
	.then (tpl) ->
		tpl { path, body: md }

service.get '/favicon.ico', (req, res) ->
	res.sendfile nobone_favicon

service.use renderer.static(root_dir)
service.use '/assets', renderer.static(assets_dir)
kit.log "Static folder: " + root_dir.cyan + ', ' + assets_dir.cyan

service.listen port, host, ->
	kit.log "Listen: " + "#{host}:#{port}".cyan
	kit.open 'http://127.0.0.1:' + port
