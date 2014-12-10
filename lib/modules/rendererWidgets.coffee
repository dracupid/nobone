###*
 * It use the renderer module to create some handy functions.
###
Overview = 'rendererWidgets'

_ = require 'lodash'
nobone = require '../nobone'
kit = require '../kit'
{ Promise, fs } = kit

express = require 'express'

module.exports = rendererWidgets =
	genFileHandlers: ->
		'.html':
			# Whether it is a default handler, optional.
			default: true
			extSrc: ['.ejs', '.jade']
			enableFileCache: false
			dependencyReg: {
				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/
			}
			###*
			 * The compiler can handle any type of file.
			 * @context {FileHandler} Properties:
			 * ```coffeescript
			 * {
			 * 	ext: String # The current file's extension.
			 * 	opts: Object # The current options of renderer.
			 *
			 * 	# The file dependencies of current file.
			 * 	# If you set it in the `compiler`, the `dependencyReg`
			 * 	# and `dependencyRoots` should be left undefined.
			 * 	depsList: Array
			 *
			 * 	# The regex to match dependency path. Regex or Table.
			 * 	dependencyReg: RegExp
			 *
			 * 	# The root directories for searching dependencies.
			 * 	dependencyRoots: Array
			 *
			 * 	# The source map informantion.
			 * 	# If you need source map support, the `sourceMap`property
			 * 	# must be set during the compile process.
			 * 	# If you use inline source map, this property shouldn't be set.
			 * 	sourceMap: String or Object
			 * }
			 * ```
			 * @param  {String} str Source content.
			 * @param  {String} path For debug info.
			 * @param  {Any} data The data sent from the `render` function.
			 * when you call the `render` directly. Default is an object:
			 * ```coffeescript
			 * {
			 * 	_: lodash
			 * 	injectClient: kit.isDevelopment()
			 * }
			 * ```
			 * @return {Promise} Promise that contains the compiled content.
			###
			compiler: (str, path, data) ->
				self = @
				switch @ext
					when '.ejs'
						compiler = kit.require 'ejs'
						tplFn = compiler.compile str, { filename: path }
					when '.jade'
						try
							compiler = kit.require 'jade'
							tplFn = compiler.compile str, { filename: path }
							@depsList = tplFn.dependencies
						catch e
							kit.err '"npm install jade" first.'.red
							process.exit()

				render = (data) ->
					_.defaults data, {
						_
						injectClient: kit.isDevelopment()
					}
					html = tplFn data
					if data.injectClient and
					self.opts.injectClientReg.test html
						html += nobone.client()
					html

				if _.isObject data
					render data
				else
					func = (data = {}) ->
						render data
					func.toString = -> str
					func

		'.js':
			extSrc: '.coffee'
			compiler: (str, path, data = {}) ->
				coffee = kit.require 'coffee-script'
				coffee.compile str, _.defaults(data, {
					bare: true
					compress: kit.isProduction()
					compressOpts: { fromString: true }
				})

		'.jsb':
			type: '.js'
			dependencyReg: /require\s+([^\r\n]+)/
			extSrc: '.coffee'
			compiler: (nil, path, data = {}) ->
				try
					browserify = kit.require 'browserify'
					through = kit.require 'through'
				catch
					kit.err '"npm install browserify through" first.'.red
					process.exit()

				coffee = kit.require 'coffee-script'

				_.defaults(data, {
					bare: true
					compress: kit.isProduction()
					compressOpts: { fromString: true }
					browserify:
						extensions: '.coffee'
						debug: kit.isDevelopment()
				})

				b = browserify data.browserify
				b.add path
				b.transform ->
					str = ''
					through(
						(chunk) -> str += chunk
						->
							this.queue coffee.compile(str, data)
							this.queue null
					)
				Promise.promisify(b.bundle, b)()

		'.css':
			extSrc: ['.styl', '.less', '.sass', '.scss']
			dependencyReg: {
				'.sass': /@import\s+([^\r\n]+)/
				'.scss': /@import\s+([^\r\n]+)/
			}
			compiler: (str, path, data = {}) ->
				self = @
				_.defaults data, {
					filename: path
				}
				switch @ext
					when '.styl'
						try
							stylus = kit.require 'stylus'
						catch e
							kit.err '"npm install stylus" first.'.red
							process.exit()

						_.defaults data, {
							sourcemap:
								inline: kit.isDevelopment()
						}
						styl = stylus(str, data)
						@depsList = styl.deps()
						Promise.promisify(styl.render, styl)()

					when '.less'
						try
							less = kit.require('less')
						catch e
							kit.err '"npm install less@1.7.5" first.'.red
							process.exit()

						parser = new less.Parser(_.defaults data, {
							sourceMapFileInline: kit.isDevelopment()
							sourceMap: kit.isDevelopment()
						})
						new Promise (resolve, reject) ->
							parser.parse str, (err, tree) ->
								if err
									kit.log err.stack
									# The error message of less is the worst.
									err.message = err.filename +
										":#{err.line}:#{err.column}\n" +
										err.message
									reject err
								else
									self.depsList = _.keys(
										parser.imports.files
									)
									resolve tree.toCSS(data)

					when '.sass', '.scss'
						try
							sass = kit.require 'node-sass'
						catch e
							kit.err '"npm install node-sass" first.'.red
							process.exit()
						sass.renderSync _.defaults data, {
							outputStyle:
								if kit.isProduction()
									'compressed'
								else
									'nested'
							file: path
							data: str
							includePaths: [kit.path.dirname(path)]
						}

		'.md':
			type: '.html'
			extSrc: ['.md','.markdown']
			compiler: (str, path, data = {}) ->
				marked = kit.require 'marked'
				marked str, data

	dir: (opts = {}) ->
		if _.isString opts
			opts = { rootDir: opts }

		_.defaults opts, {
			renderer: {
				enableWatcher: false
				autoLog: false
				cacheDir: kit.path.join __dirname, '/../.nobone/rendererCache'
			}
			rootDir: '.'
		}

		renderer = require('./renderer')(opts.renderer)

		return (req, res, next) ->
			path = kit.path.join(opts.rootDir, req.path)
			kit.dirExists path
			.then (exists) ->
				if exists
					if req.path.slice(-1) == '/'
						kit.readdir path
					else
						Promise.reject 'not strict dir path'
				else
					Promise.reject 'no dir found'
			.then (list) ->
				list.unshift '.'
				if req.path != '/'
					list.unshift '..'

				kit.async list.map (p) ->
					fp = kit.path.join opts.rootDir, req.path, p
					kit.stat(fp).then (stats) ->
						stats.isDir = stats.isDirectory()
						if stats.isDir
							stats.path = p + '/'
						else
							stats.path = p
						stats.ext = kit.path.extname p
						stats.size = stats.size
						stats
					.then (stats) ->
						if stats.isDir
							kit.readdir(fp).then (list) ->
								stats.dirCount = list.length
								stats
						else
							stats
			.then (list) ->
				list.sort (a, b) -> a.path.localeCompare b.path

				list = _.groupBy list, (el) ->
					if el.isDir
						'dirs'
					else
						'files'

				list.dirs ?= []
				list.files ?= []

				assets = (name) ->
					kit.path.join(__dirname, '../../assets/dir', name)

				kit.async [
					renderer.render assets('index.html')
					renderer.render assets('default.css')
				]
				.then ([fn, css]) ->
					res.send fn({ list, css, path: req.path })
			.catch (err) ->
				if err == 'not strict dir path'
					return res.redirect req.path + '/'

				if err != 'no dir found'
					kit.err err

				next()

	static: (renderer, opts = {}) ->
		if _.isString opts
			opts = { rootDir: opts }

		_.defaults opts, {
			rootDir: '.'
			index: kit.isDevelopment()
			injectClient: kit.isDevelopment()
			reqPathHandler: (path) -> decodeURIComponent path
		}

		staticHandler = express.static opts.rootDir
		if opts.index
			dirHandler = renderer.dir {
				rootDir: opts.rootDir
			}

		(req, res, next) ->
			reqPath = opts.reqPathHandler req.path
			path = kit.path.join opts.rootDir, reqPath

			rnext = ->
				if dirHandler
					dirHandler req, res, ->
						staticHandler req, res, next
				else
					staticHandler req, res, next

			p = renderer.render path, true, reqPath

			p.then (content) ->
				handler = p.handler
				res.type handler.type or handler.extBin

				switch content? and content.constructor.name
					when 'Number'
						body = content.toString()
					when 'String', 'Buffer'
						body = content
					when 'Function'
						body = content()
					else
						body = 'The compiler should produce a number,
							string, buffer or function: '.red +
							path.cyan + '\n' + kit.inspect(content).yellow
						err = new Error(body)
						err.name = 'unknownType'
						Promise.reject err

				if opts.injectClient and
				res.get('Content-Type').indexOf('text/html;') == 0 and
				renderer.opts.injectClientReg.test(body) and
				body.indexOf(nobone.client()) == -1
					body += nobone.client()

				if handler.sourceMap
					body += handler.sourceMap

				res.send body
			.catch (err) ->
				switch err.name
					when renderer.e.compileError
						res.status(500).end renderer.e.compileError
					when 'fileNotExists', 'noMatchedHandler'
						rnext()
					else
						Promise.reject err
			.done()

	staticEx: (renderer, opts = {}) ->
		if _.isString opts
			opts = { rootDir: opts }

		renderer.fileHandlers['.md'].compiler = (str, path) ->
			marked = kit.require 'marked'

			try
				md = marked str
			catch err
				return Promise.reject err

			Promise.all([
				'index.html'

				'sh/shCore.js'
				'sh/brushes.js'
				'main.js'

				'sh/shCoreDefault.css'
				'default.css'
			].map (path) ->
				path = kit.path.join __dirname, '../../assets/markdown', path
				renderer.render path, false
			).then ([tpl, shCore, shBrush, main, shStyle, style]) ->
				js = [shCore, shBrush, main].join('\n\n')
				css = [shStyle, style].join('\n\n')
				tpl { path, body: md, js, css }

		staticMiddleware = rendererWidgets.static renderer, opts

		(req, res, next) ->
			if req.query.source?
				path = kit.path.join opts.rootDir, req.path
				kit.readFile path, 'utf8'
				.then (str) ->
					md = "`````````#{req.query.source}\n#{str}\n`````````"
					renderer.fileHandlers['.md'].compiler md, req.path
				.then (html) ->
					res.send html
			else
				staticMiddleware req, res, next

