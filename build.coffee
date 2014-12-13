kit = require './lib/kit'
{ Promise, _ } = kit

module.exports = (opts) ->
	compileCoffee()
	compileStylus()

	if opts.bare
		return

	kit.compose(
		lintCoffee
		buildDocs
	)()

compileCoffee = ->
	kit.log "Compile coffee..."

	kit.spawn 'coffee', [
		'-o', 'dist'
		'-cb', 'lib'
	]

	kit.spawn 'coffee', [
		'-cb', 'assets'
	]

compileStylus = ->
	kit.log 'Compile stylus...'

	kit.glob 'assets/**/*.styl'
	.then (list) ->
		kit.spawn 'stylus', list

lintCoffee = ->
	kit.compose(
		kit.glob([
			'lib/**/*.coffee'
			'test/**/*.coffee'
			'examples/**/*.coffee'
		])
		(list) ->
			kit.spawn 'coffeelint', list
		({ code, signal }) ->
			if code != 0
				process.exit()
	)()

buildDocs = ->
	kit.log 'Make readme...'
	Promise.all([
		kit.readFile 'doc/faq.md', 'utf8'
		kit.readFile 'doc/readme.ejs.md', 'utf8'
		kit.readFile 'examples/basic.coffee', 'utf8'
		kit.readFile 'benchmark/mem_vs_stream.coffee', 'utf8'
		kit.readFile 'benchmark/crc_vs_jhash.coffee', 'utf8'
		kit.glob 'examples/*.coffee'
	]).then (rets) ->
		faq = rets[0]
		basic = rets[2]

		data = {
			tpl: rets[1]
			basic
			faq
			mods: [
				'lib/nobone.coffee'
				'lib/kit.coffee'
				'lib/modules/service.coffee'
				'lib/modules/renderer.coffee'
				'lib/modules/rendererWidgets.coffee'
				'lib/modules/db.coffee'
				'lib/modules/proxy.coffee'
				'lib/modules/lang.coffee'
			]
			benchmark: kit.parseComment 'benchmark', rets[3] + rets[4]
			examples: rets[5].map(
					(l) -> "- [#{kit.path.basename(l, '.coffee')}](#{l})"
				).join('\n')
		}

		Promise.all data.mods.map (path) ->
			name = kit.path.basename path, '.coffee'
			kit.readFile path, 'utf8'
			.then (code) ->
				kit.parseComment name, code, path
		.then (rets) ->
			data.mods = _.groupBy _.flatten(rets, true), (el) -> el.module
			data
	.then (data) ->
		ejs = require 'ejs'
		data._ = _

		indent = (str, num = 0) ->
			s = _.range(num).reduce ((s) -> s + ' '), ''
			s + str.trim().replace(/\n/g, '\n' + s)

		data.modsApi = ''

		for modName, mod of data.mods
			data.modsApi += """### #{modName}\n\n"""
			for method in mod
				method.name = method.name.replace 'self.', ''
				sourceLink = "#{method.path}?source#L#{method.line}"
				methodStr = indent """
					- #### <a href="#{sourceLink}" target="_blank"><b>#{method.name}</b></a>
				"""
				methodStr += '\n\n'
				if method.description
					methodStr += indent method.description, 1
					methodStr += '\n\n'

				if _.any(method.tags, { tagName: 'private' })
					continue

				for tag in method.tags
					tname = if tag.name then "`#{tag.name}`" else ''
					ttype = if tag.type then "{ _#{tag.type}_ }" else ''
					methodStr += indent """
						- **<u>#{tag.tagName}</u>**: #{tname} #{ttype}
					""", 1
					methodStr += '\n\n'
					if tag.description
						methodStr += indent tag.description, 4
						methodStr += '\n\n'

				data.modsApi += methodStr

		out = ejs.render data.tpl, data

		kit.outputFile 'readme.md', out
