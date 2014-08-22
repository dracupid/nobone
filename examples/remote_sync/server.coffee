nobone = require 'nobone'

token = '123'

{ kit, service } = nobone()

service.post '/:type/:path', (req, res) ->
	# Check token
	try
		req_token = kit.decrypt(
			new Buffer(req.query.token, 'hex')
			token
			true
		)
		if req_token != token
			res.status(403).end 'auth_err'
			return
	catch err
		kit.err err
		res.status(403).end 'auth_err'
		return

	type = req.params.type
	path = req.params.path

	kit.log type.cyan + ': ' + path

	p = kit.Q()

	data = new Buffer(0)
	req.on 'data', (chunk) ->
		data = Buffer.concat [data, chunk]

	req.on 'end', ->
		switch req.params.type
			when 'create'
				if path[-1..] == '/'
					p = p.then kit.mkdirs(path)
				else
					p = p.then kit.outputFile(path, data)
			when 'modify'
					p = p.then kit.outputFile(path, data)
			when 'delete'
					p = p.then kit.remove(path)

		p.then ->
			res.send 'ok'
		.catch (err) ->
			res.status(500).end err

service.listen 8345
