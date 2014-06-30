nb = require 'nobone'

nb.get '/', (req, res) ->
	res.send '<%= name %>'
