nobone = require '../lib/nobone'

{ kit } = nobone()


kit.readFile 'lib/kit.coffee'
.then (code) ->
	kit.log kit.parse_comment('nobone', code)
