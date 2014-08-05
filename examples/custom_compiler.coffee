nobone = require 'nobone'

nb = nobone()

# Let compiler just return the char count of compiled js.
nb.renderer
.file_handlers['.js'].compiler = (str, args...) ->
	return str.length

# Render this file itself.
nb.renderer.render 'examples/custom_compiler.js', { opt: 'test' }
.done (out) ->
	nb.kit.log out