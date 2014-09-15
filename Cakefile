_ = require 'lodash'
try
	kit = require './lib/kit'
catch e
	kit = require './dist/kit'

Q = require 'q'

task 'dev', 'Dev Server', ->
	kit.monitor_app {
		bin: 'coffee'
		args: ['test/lab.coffee']
		watch_list: ['test/lab.coffee', 'lib/**/*.coffee']
	}

task 'test', 'Basic test', (options) ->
	[
		# 'test/single.coffee'
		'test/basic.coffee'
	].forEach (file) ->
		kit.spawn('mocha', [
			'-t', '5000'
			'-r', 'coffee-script/register'
			'-R', 'spec'
			file
		]).process.on 'exit', (code) ->
			if code != 0
				process.exit code

task 'build', 'Compile coffee to js', build = ->
	kit.log "Compile coffee..."

	kit.spawn 'coffee', [
		'-o', 'dist'
		'-cb', 'lib'
	]

	# Build readme
	kit.log 'Make readme...'
	Q.all([
		kit.readFile 'doc/faq.md', 'utf8'
		kit.readFile 'doc/readme.ejs.md', 'utf8'
		kit.readFile 'examples/basic.coffee', 'utf8'
		kit.readFile 'benchmark/mem_vs_stream.coffee', 'utf8'
		kit.readFile 'benchmark/crc_vs_jhash.coffee', 'utf8'
	]).then (rets) ->
		faq = rets[0]
		basic = rets[2]
		{
			tpl: rets[1]
			basic
			faq
			mods: [
				'lib/nobone.coffee'
				'lib/modules/service.coffee'
				'lib/modules/renderer.coffee'
				'lib/modules/db.coffee'
				'lib/modules/proxy.coffee'
				'lib/kit.coffee'
			]
			benchmark: kit.parse_comment 'benchmark', rets[3] + rets[4]
		}
	.then (data) ->
		Q.all data.mods.map (path) ->
			name = kit.path.basename path, '.coffee'
			kit.readFile path, 'utf8'
			.then (code) ->
				kit.parse_comment name, code, path
		.then (rets) ->
			data.mods = _.groupBy _.flatten(rets, true), (el) -> el.module
			data
	.then (data) ->
		ejs = require 'ejs'
		data._ = _

		indent = (str, num = 0) ->
			s = _.range(num).reduce ((s) -> s + ' '), ''
			s + str.trim().replace(/\n/g, '\n' + s)

		data.mods_api = ''

		for mod_name, mod of data.mods
			data.mods_api += """### #{mod_name}\n\n"""
			for method in mod
				method.name = method.name.replace 'self.', ''
				method_str = indent """
					- #### <a href="#{method.path}#L#{method.line}" target="_blank"><b>#{method.name}</b></a>
				"""
				method_str += '\n\n'
				if method.description
					method_str += indent method.description, 1
					method_str += '\n\n'

				for tag in method.tags
					tname = if tag.name then "`#{tag.name}`" else ''
					ttype = if tag.type then "{ _#{tag.type}_ }" else ''
					method_str += indent """
						- **<u>#{tag.tag_name}</u>**: #{tname} #{ttype}
					""", 1
					method_str += '\n\n'
					if tag.description
						method_str += indent tag.description, 3
						method_str += '\n\n'

				data.mods_api += method_str

		out = ejs.render data.tpl, data

		kit.outputFile 'readme.md', out

	.done()

task 'clean', 'Clean js', ->
	kit.log ">> Clean js..."

	kit.remove('dist').done()

# Just for fun.
task 'code', 'Code Statistics of this project', ->
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
			Q.all [
				kit.readFile paths[i], 'utf8'
				kit.stat paths[i]
			]
		.progress ([str, stats]) ->
			line_count += str.split('\n').length
			size_count += stats.size
	.done ->
		kit.log 'Total Lines: '.cyan + line_count
		kit.log ' Total Size: '.cyan + (size_count / 1024).toFixed(2) + ' kb'
