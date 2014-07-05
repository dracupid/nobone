nobone = require '../lib/nobone'

{ kit } = nobone()


kit.readFile 'lib/nobone.coffee'
.done (code) ->
	kit.log kit.parse_comment('nobone', code)
