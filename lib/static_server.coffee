nobone = require './nobone'
marked = require 'marked'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enable_watcher: true
	}
}

[ host, port, root_dir ] = process.argv[2..]
assets_dir = __dirname + '/../assets'
marked_ejs =  __dirname + '/../assets/marked.ejs'
nobone_readme = __dirname + '/../readme.md'

service.use renderer.static(root_dir)
service.use renderer.static(__dirname + '/../assets')
kit.log "Static folder: " + root_dir.cyan + ', ' + assets_dir.cyan

# Markdown support
renderer.code_handlers['.mdx'].compiler = (str, path) ->
	md = marked str
	renderer.render marked_ejs
	.then (tpl) ->
		tpl {
			path
			body: md + renderer.auto_reload()
		}

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
