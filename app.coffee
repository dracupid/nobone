nobone = require 'nobone'
{ kit } = nobone

kit.glob [
	'Cakefile'
	'build.coffee'
].concat [
	'assets'
	'bone'
	'doc'
	'examples'
	'lib'
	'test'
].map (e) -> e + '/**/*.+(coffee|ejs|md)'
.then (paths) ->
	paths.map (p) ->
		to = p.replace /([a-z])_([a-z])/ig, (m, p1, p2) ->
			p1 + p2.toUpperCase()

		kit.log to

		kit.move p, to
		.catch(->)

	# kit.async paths.map (p) ->
	# 	kit.readFile p, 'utf8'
	# 	.then (str) ->
	# 		str.replace /[$A-Z_][\w$]*/ig, (m) ->
	# 			m.replace /([a-z])_([a-z])/ig, (m, p1, p2) ->
	# 				p1 + p2.toUpperCase()
	# 	.then (str) ->
	# 		kit.log 'Compiled: '.cyan + p
	# 		kit.outputFile p, str