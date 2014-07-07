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
marked_ejs =  kit.path.normalize __dirname + '/../assets/markdown/index.ejs'
nobone_readme = kit.path.normalize __dirname + '/../readme.md'
nobone_favicon = kit.path.normalize __dirname + '/../assets/img/nobone.png'

service.use renderer.static(root_dir)
service.use renderer.static(__dirname + '/../assets')
kit.log "Static folder: " + root_dir.cyan + ', ' + assets_dir.cyan

# Markdown support
renderer.code_handlers['.md'].compiler = (str, path) ->
	md = marked str
	renderer.render marked_ejs
	.then (tpl) ->
		tpl {
			path
			body: md + renderer.auto_reload()
		}

service.get '/favicon.ico', (req, res) ->
	res.sendfile nobone_favicon

service.get '/nobone', (req, res) ->
	Q = require 'q'
	Q.all([
		renderer.render marked_ejs
		kit.readFile nobone_readme, 'utf8'
	])
	.done (rets) ->
		[tpl, md] = rets
		res.send tpl({
			path: 'Nobone'
			body: marked md
		})

service.listen port, host
kit.log "Listen: " + "#{host}:#{port}".cyan
