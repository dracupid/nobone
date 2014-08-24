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
				p = kit.move path, data.toString()
			when 'delete'
				p = kit.remove path
			else
				res.status(403).end 'unknown_type'
				return

		p.then ->
			res.send 'ok'
		.catch (err) ->
			res.status(500).end err

service.listen 8345
