nobone = require './nobone'

{ kit, renderer, service } = nobone.create {
	service: {}
	renderer: {
		enable_watcher: true
	}
}

[ host, port, root_dir ] = process.argv[2..]

service.use renderer.static({ root_dir })
kit.log "Static folder: " + root_dir.cyan

renderer.on 'watch_file', (path) ->
	kit.log "Watch: #{path}".cyan

renderer.on 'file_modified', (path) ->
	kit.log "Modified: #{path}".cyan

renderer.on 'compile_error', (path, err) ->
	kit.log (path + '\n' + err.toString()).red, 'error'


service.listen port, host
kit.log "Listen: " + "#{host}:#{port}".cyan
