module.exports = (opts) ->
	compileCoffee()
	compileStylus()

	if opts.bare
		return Promise.resolve()

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

	Promise.all [
		'doc/readme.tpl.md'
		'doc/faq.md'
		'examples/basic.coffee'
	].map (path) ->
		kit.readFile path, 'utf8'
	.then (rets) ->
		kit.glob 'examples/*.coffee'
		.then (paths) ->
			rets.push paths.map(
				(l) -> "- [#{kit.path.basename(l, '.coffee')}](#{l}?source)"
			).join('\n')
			rets
	.then ([tpl, faq, basic, examples]) ->

		Promise.all [
			'lib/nobone.coffee'
			'lib/kit.coffee'
			'lib/modules/service.coffee'
			'lib/modules/renderer.coffee'
			'lib/modules/rendererWidgets.coffee'
			'lib/modules/db.coffee'
			'lib/modules/proxy.coffee'
			'lib/modules/lang.coffee'
		].map (path) ->
			name = kit.path.basename path, '.coffee'
			kit.parseFileComment path, {
				formatComment: {
					name: ({ name, line }) ->
						name = name.replace 'self.', ''
						link = "#{path}?source#L#{line}"
						"- #### **[#{name}](#{link})**\n\n"
				}
			}
			.then (mod) -> [name, mod]
		.then (mods) ->
			modsApi = ''

			for [name, mod] in mods
				modsApi += "### #{name}\n#{mod}"

			out = _.template(tpl) { faq, basic, modsApi, examples }

			kit.outputFile 'readme.md', out
