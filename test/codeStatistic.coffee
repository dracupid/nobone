kit = require '../lib/kit'

lineCount = 0
sizeCount = 0

kit.glob [
	'assets', 'benchmark', 'bin', 'bone', 'doc', 'examples', 'lib', 'test'
].map (el) -> el + '/**/*.+(js|coffee|styl|css|md|ejs|html)'
.then (paths) ->
	paths.push 'Cakefile'

	kit.log ' File Count: ' + paths.length

	kit.async 20, (i) ->
		if i >= paths.length
			return
		Promise.all [
			kit.readFile paths[i], 'utf8'
			kit.stat paths[i]
		]
	, false, ([str, stats]) ->
		lineCount += str.split('\n').length
		sizeCount += stats.size
.then ->
	kit.log 'Total Lines: ' + lineCount
	kit.log ' Total Size: ' + (sizeCount / 1024).toFixed(2) + ' kb'
