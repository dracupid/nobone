nobone = require 'nobone'

nb = nobone()

file_path = 'examples/custom_compiler.coffee'

# Let compiler just return the char count of compiled js.
nb.renderer
.file_handlers['.js'].compiler = (str, args...) ->
	nb.kit.log args
	return str.length

nb.renderer.render file_path, { opt: 'test' }
.done (out) ->
	nb.kit.log out