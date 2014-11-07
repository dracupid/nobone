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
	kit.Promise.promisify('render', stylus)(str)
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

# If js and coffee file both exist, only compile js file.
renderer.file_handlers['.js'] = {
	ext_src: ['.js', '.coffee']
	compiler: (str) ->
		return str if @ext == '.js'

		coffee = kit.require 'coffee-script'
		coffee.compile str
}

# We can also use a wrap pattern to achieve the above handler.
# In this way we can keep the default behavior of the renderer.
renderer.file_handlers['.js'] = {
	ext_src: ['.js', '.coffee']
	compiler: kit._.wrap(
		renderer.file_handlers['.js'].compiler
		(old_compiler, str, path, data) ->
			return str if @ext == '.js'

			old_compiler.call this, str, path, data
	)
}

# After all settings, set static folder.
service.use renderer.static('examples/fixtures')

service.listen 8293, ->
	kit.log 'Listen: 8293'
