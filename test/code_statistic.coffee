kit = require '../lib/kit'

line_count = 0
size_count = 0

kit.glob [
	'assets', 'benchmark', 'bin', 'bone', 'doc', 'examples', 'lib', 'test'
].map (el) -> el + '/**/*.+(js|coffee|styl|css|md|ejs|html)'
.then (paths) ->
	paths.push 'Cakefile'

	kit.log ' File Count: '.cyan + paths.length

	kit.async 20, (i) ->
		if i >= paths.length
			return
		Promise.all [
			kit.readFile paths[i], 'utf8'
			kit.stat paths[i]
		]
	, false, ([str, stats]) ->
		line_count += str.split('\n').length
		size_count += stats.size
.done ->
	kit.log 'Total Lines: '.cyan + line_count
	kit.log ' Total Size: '.cyan + (size_count / 1024).toFixed(2) + ' kb'
