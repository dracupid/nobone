nobone = require 'nobone'

{ renderer, kit, service } = nobone()

# Delete the jpg handler.
delete renderer.file_handlers['.jpg']

# Custom an exists handler.
# When browser visit 'http://127.0.0.1:8293/default.css'
# The css with extra comment will be sent back.
renderer
.file_handlers['.css'].compiler = (str, args...) ->
	stylus = kit.require 'stylus'
	kit.Q.ninvoke stylus, 'render', str
	.then (str) ->
		'/* nobone */' + str

# Add a new handler.
# When browser visit 'http://127.0.0.1:8293/test.count'
# It will automatically find 'test.coffee' file and
# send the text length back to the browser as html.
renderer.file_handlers['.count'] = {
	type: '.html'
	ext_src: ['.txt']
	compiler: (str) ->
		str.length
}

service.use renderer.static('examples/fixtures')

service.listen 8293
