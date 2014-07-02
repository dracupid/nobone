nobone = require '../lib/nobone'

{ kit } = nobone.create()


kit.readFile 'lib/nobone.coffee'
.then (code) ->
	kit.log kit.parse_comment('nobone', code)
