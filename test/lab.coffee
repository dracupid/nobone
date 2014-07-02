nobone = require '../lib/nobone'

nb = nobone.create()

nb.service.get '/', (req, res) ->
	res.send 'ok'

nb.service.listen '8013'