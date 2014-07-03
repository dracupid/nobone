nobone = require '../lib/nobone'

{ kit } = nobone.create()


kit.readFile 'lib/kit.coffee'
.then (code) ->
	kit.log kit.parse_comment('nobone', code)
