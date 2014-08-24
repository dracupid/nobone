# Watch and sync a local folder with a remote one.
# All the local operations will be repeated on the remote.
#
# This this the remote server.


nobone = require 'nobone'

{ kit, service } = nobone()

service.post '/:type/:path', (req, res) ->
	type = req.params.type
	path = req.params.path

	kit.log type.cyan + ': ' + path

	data = new Buffer(0)
	req.on 'data', (chunk) ->
		data = Buffer.concat [data, chunk]

	req.on 'end', ->
		switch req.params.type
			when 'create'
				if path[-1..] == '/'
					p = kit.mkdirs(path)
				else
					p = kit.outputFile path, data
			when 'modify'
				p = kit.outputFile path, data
			when 'move'
				kit.log data.toString()
				p = kit.move data.toString(), path
			when 'delete'
				p = kit.remove path
			else
				res.status(403).end 'unknown_type'
				return

		p.then ->
			res.send 'ok'
		.catch (err) ->
			kit.err err
			res.status(500).end err.stack

service.listen 8345
