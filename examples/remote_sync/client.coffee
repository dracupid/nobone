nobone = require 'nobone'

local_dir = 'examples/fixtures'
remote_dir = 'examples/remote_dir'
host = 'http://127.0.0.1:8345'
token = '123'

{ kit } = nobone()

process.env.watch_persistent = 'on'

kit.watch_dir {
	dir: local_dir
	handler: (type, path) ->
		kit.log type.cyan + ': ' + path
		remote_path = encodeURIComponent(
			kit.path.join remote_dir, path.replace(local_dir, '').replace('/', '')
		)
		req_token = kit.encrypt(token, token, true).toString('hex')
		rdata = {
			url: host + "/#{type}/#{remote_path}?token=#{req_token}"
			method: 'POST'
		}

		p = kit.Q()

		switch type
			when 'create', 'modify'
				if path[-1..] != '/'
					p = p.then ->
						kit.readFile path
					.then (data) ->
						rdata.req_data = data

		p = p.then ->
			kit.request rdata
		.then (data) ->
			if data == 'ok'
				kit.log 'Synced: '.green + path
			else
				kit.err data
		.catch (err) ->
			kit.err err
}
