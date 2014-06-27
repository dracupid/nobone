
_ = require './_'
{ renderer } = require './nobone'

renderer.on 'watch_file', (path) ->
	_.log "Watch: #{path}".cyan

renderer.on 'file_modified', (path) ->
	_.log "Modified: #{path}".cyan

renderer.on 'compile_error', (path, err) ->
	_.log (path + '\n' + err.toString()).red, 'error'
