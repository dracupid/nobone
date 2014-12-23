###*
 * It use the renderer module to create some handy functions.
###
Overview = 'rendererWidgets'

_ = require 'lodash'
nobone = require '../nobone'
kit = require '../kit'
http = require 'http'
{ Promise, fs } = kit

module.exports = rendererWidgets =
	genFileHandlers: ->
		'.html':
			# Whether it is a default handler, optional.
			default: true
			extSrc: ['.tpl', '.ejs', '.jade']
			enableFileCache: false
			dependencyReg: {
				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/
			}
			###*
			 * The compiler can handle any type of file.
			 * @context {FileHandler} Properties:
			 * ```coffee
			 * {
			 * 	ext: String # The current file's extension.
			 * 	opts: Object # The current options of renderer.
			 *
			 * 	# The file dependencies of current file.
			 * 	# If you set it in the `compiler`, the `dependencyReg`
			 * 	# and `dependencyRoots` should be left undefined.
			 * 	dependencyPaths: Array
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
			 * ```coffee
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
					when '.tpl'
						tplFn = _.template str, null, { sourceURL: path }

					when '.ejs'
						try
							compiler = kit.require 'ejs'
						catch e
							kit.err '"npm install ejs" first.'.red
							process.exit()

						tplFn = compiler.compile str, { filename: path }
					when '.jade'
						try
							compiler = kit.require 'jade'
						catch e
							kit.log e
							kit.err '"npm install jade" first.'.red
							process.exit()

						tplFn = compiler.compile str, { filename: path }
						@dependencyPaths = tplFn.dependencies

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

				try
					if _.isObject data
						render data
					else
						func = (data = {}) ->
							render data
						func.toString = -> str
						func
				catch err
					Promise.reject err

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
				kit.promisify(b.bundle, b)()

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
						@dependencyPaths = styl.deps()
						kit.promisify(styl.render, styl)()

					when '.less'
						try
							less = kit.require('less')
						catch e
							kit.err '"npm install less" first.'.red
							process.exit()
						if less.version[0] < 2 # old API for less < 2.0.0
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
										self.dependencyPaths = _.keys(
											parser.imports.files
										)
										resolve tree.toCSS(data)
						else
							opts = {}
							if kit.isDevelopment()
								opts =
									sourceMap:
										sourceMapFileInline: true

							less.render str, _.defaults data, opts
							.then (output) ->
								self.dependencyPaths = output.imports
								output.css
							, (err) ->
								kit.log err.stack
								# The error message of less is the worst.
								err.message = err.filename +
									":#{err.line}:#{err.column}\n" +
									err.message
								Promise.reject err

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

	###*
	 * Folder middleware.
	 * @param  {Object} opts
	 * @return {Function}
	###
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
			reqPathHandler: (path) -> decodeURIComponent path
		}

		renderer = require('./renderer')(opts.renderer)

		return (req, res, next) ->
			reqPath = opts.reqPathHandler req.path
			path = kit.path.join(opts.rootDir, reqPath)
			kit.dirExists path
			.then (exists) ->
				if exists
					if reqPath.slice(-1) == '/'
						kit.readdir path
					else
						Promise.reject 'not strict dir path'
				else
					Promise.reject 'no dir found'
			.then (list) ->
				list.unshift '.'
				if reqPath != '/'
					list.unshift '..'

				kit.async list.map (p) ->
					fp = kit.path.join opts.rootDir, reqPath, p
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
					res.send fn({ list, css, path: reqPath })
			.catch (err) ->
				if err == 'not strict dir path'
					return res.redirect reqPath + '/'

				if err != 'no dir found'
					kit.err err

				next()

	###*
	 * Static middleware.
	 * @param  {Renderer} renderer
	 * @param  {Object} opts
	 * @return {Function}
	###
	static: (renderer, opts = {}) ->
		express = kit.require 'express'

		if _.isString opts
			opts = { rootDir: opts }

		_.defaults opts, {
			rootDir: process.cwd()
			index: kit.isDevelopment()
			injectClient: kit.isDevelopment()
			reqPathHandler: decodeURIComponent
			isMalicious: (path) ->
				kit.path.normalize(path).indexOf(@rootDir) != 0
		}

		opts.rootDir = kit.path.resolve opts.rootDir

		staticHandler = express.static opts.rootDir
		if opts.index
			dirHandler = renderer.dir {
				rootDir: opts.rootDir
			}

		(req, res, next) ->
			reqPath = opts.reqPathHandler req.path
			path = kit.path.join opts.rootDir, reqPath

			if opts.isMalicious path
				return res.status(403).end http.STATUS_CODES[403]

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

	###*
	 * Static middleware. Don't use it in production.
	 * @param  {Renderer} renderer
	 * @param  {Object} opts
	 * @return {Function}
	###
	staticEx: (renderer, opts = {}) ->
		if _.isString opts
			opts = { rootDir: opts }

		_.defaults opts, {
			rootDir: '.'
			index: kit.isDevelopment()
			injectClient: kit.isDevelopment()
			reqPathHandler: decodeURIComponent
		}

		noboneRoot = kit.path.join __dirname, '../..'
		assetsRoot = kit.path.join noboneRoot, 'assets'

		renderer.fileHandlers['.md'].compiler = (str, path) ->
			marked = kit.require 'marked'

			try
				md = marked str
			catch err
				return Promise.reject err

			tplPath = kit.path.join assetsRoot, 'markdown/index.tpl'

			kit.readFile tplPath, 'utf8'
			.then (str) ->
				try
					_.template str, { path, body: md, sourceURL: tplPath }
				catch err
					Promise.reject err

		staticMiddleware = rendererWidgets.static renderer, opts

		(req, res, next) ->
			reqPath = opts.reqPathHandler req.path

			if req.query.noboneAssets?
				path = req.path.replace /.*assets/, ''
				res.sendFile path, { root: assetsRoot }, (err) ->
					next() if err

			else if req.query.gotoDoc?
				currModulePath = reqPath.replace(/\/[^\/]+$/, '/')

				paths = kit.generateNodeModulePaths(
					req.query.gotoDoc.replace('/', kit.path.sep)
					kit.path.join opts.rootDir, currModulePath
				)

				for path in paths
					if kit.fs.existsSync path
						url = kit.path
							.relative(opts.rootDir, path)
							.replace(kit.path.sep, '/')
						res.redirect '/' + url + '?offlineMarkdown'
						return
				next()

			else if req.query.offlineMarkdown?
				path = kit.path.join opts.rootDir, reqPath
				kit.readFile path, 'utf8'
				.then (md) ->
					# Remove the online images. Image loading may stuck the page.
					md = md.replace /!\[([^\[\]]+?)\]\(http.+?\)/g, (m, p) -> p
					renderer.fileHandlers['.md'].compiler md, reqPath
				.then (html) ->
					res.send html
				.catch (err) ->
					if err.code == 'ENOENT'
						next()
					else
						kit.err err.stack or err
						res.send err.toString()

			else if req.query.source?
				path = kit.path.join opts.rootDir, reqPath
				type = req.query.source or
					kit.path.extname(reqPath)[1..] or
					kit.path.basename(reqPath)
				type = encodeURIComponent type
				kit.readFile path, 'utf8'
				.then (str) ->
					md = "`````````#{type}\n#{str}\n`````````"
					renderer.fileHandlers['.md'].compiler md, reqPath
				.then (html) ->
					res.send html
				.catch (err) ->
					if err.code == 'ENOENT'
						next()
					else
						kit.err err.stack or err
						res.send err.toString()

			else
				staticMiddleware req, res, next