###*
 * An abstract renderer for any content, such as source code or image files.
 * It automatically uses high performance memory cache.
 * This renderer helps nobone to build a **passive compilation architecture**.
 * You can run the benchmark to see the what differences it makes.
 * Even for huge project the memory usage is negligible.
 * @extends {events.EventEmitter} [Documentation](http://nodejs.org/api/events.html#eventsClassEventsEventemitter)
###
Overview = 'renderer'

kit = require '../kit'
express = require 'express'
{ EventEmitter } = require 'events'
{ _, Promise, fs } = kit

rendererWidgets = require './rendererWidgets'

###*
 * Create a Renderer instance.
 * @param {Object} opts Defaults:
 * ```coffee
 * {
 * 	enableWatcher: kit.isDevelopment()
 * 	autoLog: kit.isDevelopment()
 *
 * 	# If renderer detects this pattern, it will auto-inject `noboneClient.js`
 * 	# into the page.
 * 	injectClientReg: /<html[^<>]*>[\s\S]*<\/html>/i
 *
 * 	cacheDir: '.nobone/rendererCache'
 * 	cacheLimit: 1024

 * 	fileHandlers: {
 * 		'.html': {
 * 			default: true
 * 			extSrc: ['.tpl','.ejs', '.jade']
 * 			# Extra files to watch.
 * 			extraWatch: { path1: 'comment1', path2: 'comment2', ... }
 * 			encoding: 'utf8' # optional, default is 'utf8'
 * 			dependencyReg: {
 * 				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/g
 * 			}
 * 			compiler: (str, path, data) -> ...
 * 		}
 *
 * 		# Simple coffee compiler
 * 		'.js': {
 * 			extSrc: '.coffee'
 * 			compiler: (str, path) -> ...
 * 		}
 *
 * 		# Browserify a main entrance file.
 * 		'.jsb': {
 * 			type: '.js'
 * 			extSrc: '.coffee'
 * 			dependencyReg: /require\s+([^\r\n]+)/g
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.css': {
 * 			extSrc: ['.styl', '.less', '.sass', '.scss']
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.md': {
 * 			type: 'html' # Force type, optional.
 * 			extSrc: ['.md', '.markdown']
 * 			compiler: (str, path) -> ...
 * 		}
 * 	}
 * }
 * ```
 * @return {Renderer}
###
renderer = (opts) -> new Renderer(opts)


class Renderer extends EventEmitter then constructor: (opts = {}) ->

	super

	_.defaults opts, {
		enableWatcher: kit.isDevelopment()
		autoLog: kit.isDevelopment()
		injectClientReg: /<html[^<>]*>[\s\S]*<\/html>/i
		cacheDir: '.nobone/rendererCache'
		cacheLimit: 1024
		fileHandlers: rendererWidgets.genFileHandlers()
	}

	self = @

	self.opts = opts

	cachePool = {}

	# Async lock, make sure one file won't be handled twice.
	renderQueue = {}

	###*
	 * You can access all the fileHandlers here.
	 * Manipulate them at runtime.
	 * @type {Object}
	 * @example
	 * ```coffee
	 * { renderer } = nobone()
	 * renderer.fileHandlers['.css'].compiler = (str, path) ->
	 * 	stylus = kit.requireOptional 'stylus'
	 *
	 * 	compile = stylus(str, data).set 'filename', path
	 * 	# Take advantage of the syntax parser.
	 * 	this.dependencyPaths = compile.deps()
	 * 	kit.promisify(compile.render, compile)()
	 * ```
	###
	self.fileHandlers = opts.fileHandlers

	###*
	 * The cache pool of the result of `fileHandlers.compiler`
	 * @type {Object} Key is the file path.
	###
	self.cachePool = cachePool

	###*
	 * Set a service for listing directory content, similar with the `serve-index` project.
	 * @param  {String | Object} opts If it's a string it represents the rootDir.
	 * @return {Middleware} Experss.js middleware.
	###
	self.dir = rendererWidgets.dir

	###*
	 * Set a static directory proxy.
	 * Automatically compile, cache and serve source files for both deveopment and production.
	 * @param  {String | Object} opts If it's a string it represents the rootDir.
	 * of this static directory. Defaults:
	 * ```coffee
	 * {
	 * 	rootDir: '.'
	 *
	 * 	# Whether enable serve direcotry index.
	 * 	index: kit.isDevelopment()
	 *
	 * 	injectClient: kit.isDevelopment()
	 *
	 * 	# Useful when mapping a normal path to a hashed file.
	 * 	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
	 * 	reqPathHandler: decodeURIComponent
	 *
	 * 	# Check path such as '../../../../etc/passwd'.
	 * 	isMalicious: ->
	 * }
	 * ```
	 * @return {Middleware} Experss.js middleware.
	###
	self.static = (opts) ->
		rendererWidgets.static self, opts

	###*
	 * An extra version of `renderer.static`.
	 * Better support for markdown and source file.
	 * @param  {String | Object} opts If it's a string it represents the rootDir.
	 * of this static directory. Defaults:
	 * ```coffee
	 * {
	 * 	rootDir: '.'
	 *
	 * 	# Whether enable serve direcotry index.
	 * 	index: kit.isDevelopment()
	 *
	 * 	injectClient: kit.isDevelopment()
	 *
	 * 	# Useful when mapping a normal path to a hashed file.
	 * 	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
	 * 	reqPathHandler: decodeURIComponent
	 * }
	 * ```
	 * @return {Middleware} Experss.js middleware.
	###
	self.staticEx = (opts) ->
		rendererWidgets.staticEx self, opts

	###*
	 * Render a file. It will auto-detect the file extension and
	 * choose the right compiler to handle the content.
	 * @param  {String | Object} path The file path. The path extension should be
	 * the same with the compiled result file. If it's an object, it can contain
	 * any number of following params.
	 * @param  {String} ext Force the extension. Optional.
	 * @param  {Object} data Extra data you want to send to the compiler. Optional.
	 * @param  {Boolean} isCache Whether to cache the result,
	 * default is true. Optional.
	 * @param {String} reqPath The http request path. Support it will make auto-reload
	 * more efficient.
	 * @param {FileHandler} handler A custom file handler.
	 * @return {Promise} Contains the compiled content.
	 * @example
	 * ```coffee
	 * # The 'a.ejs' file may not exists, it will auto-compile
	 * # the 'a.ejs' or 'a.html' to html.
	 * renderer.render('a.html').then (html) -> kit.log(html)
	 *
	 * # if the content of 'a.ejs' is '<% var a = 10 %><%= a %>'
	 * renderer.render('a.ejs', '.html').then (html) -> html == '10'
	 * renderer.render('a.ejs').then (str) -> str == '<% var a = 10 %><%= a %>'
	 * ```
	###
	self.render = (path, ext, data, isCache, reqPath, handler) ->
		if _.isObject path
			{ path, ext, data, isCache, reqPath, handler } = path

		if _.isString ext
			path = forceExt path, ext
		else if _.isBoolean ext
			handler = reqPath
			reqPath = data
			isCache = ext
			data = undefined
		else
			[data, isCache, reqPath, handler] = [ext, data, isCache, reqPath]

		isCache ?= true

		handler = genHandler path, handler

		if handler
			# If current path is under processing, wait for it.
			if renderQueue[handler.key]
				return renderQueue[handler.key]

			handler.data = data
			handler.reqPath = reqPath
			p = if isCache
				getCache(handler)
			else
				getSrc handler

			p = p.then (handler) ->
				getCompiled handler.extBin, handler, isCache
			p.handler = handler

			# Release the lock when the compilation is done.
			p.catch(->).then -> delete renderQueue[handler.key]

			renderQueue[handler.key] = p
		else
			err = new Error('No matched content handler for:' + path)
			err.name = 'noMatchedHandler'
			Promise.reject err

	###*
	 * Release the resources.
	###
	self.close = ->
		for path of cachePool
			self.releaseCache path

	###*
	 * Release memory cache of a file.
	 * @param  {String} path
	###
	self.releaseCache = (path) ->
		handler = cachePool[path]
		handler.deleted = true
		if handler.watchedList
			for wpath, watcher of handler.watchedList
				fs.unwatchFile(wpath, watcher)
		delete cachePool[path]

	self.e = {}

	###*
	 * @event {compiled}
	 * @param {String} path The compiled file.
	 * @param {String} content Compiled content.
	 * @param {FileHandler} handler The current file handler.
	###
	self.e.compiled = 'compiled'

	###*
	 * @event {compileError}
	 * @param {String} path The error file.
	 * @param {Error} err The error info.
	###
	self.e.compileError = 'compileError'

	###*
	 * @event {watchFile}
	 * @param {String} path The path of the file.
	 * @param {fs.Stats} curr Current state.
	 * @param {fs.Stats} prev Previous state.
	###
	self.e.watchFile = 'watchFile'

	###*
	 * @event {fileDeleted}
	 * @param {String} path The path of the file.
	###
	self.e.fileDeleted = 'fileDeleted'

	###*
	 * @event {fileModified}
	 * @param {String} path The path of the file.
	###
	self.e.fileModified = 'fileModified'

	jhash = new kit.jhash.constructor

	relate = (p) ->
		rp = kit.path.relative process.cwd(), p

		m = rp.match(/\.\.\//g)
		if m and m.length > 3
			p
		else
			rp

	emit = (args...) ->
		if opts.autoLog
			if args[0] == 'compileError'
				kit.err args[1].yellow + '\n' + (args[2] + '').red
			else
				kit.log [args[0].cyan].concat(args[1..]).join(' | '.grey)

		self.emit.apply self, args

	setSourceMap = (handler) ->
		if _.isObject(handler.sourceMap)
			handler.sourceMap = JSON.stringify(handler.sourceMap)

		handler.sourceMap = (new Buffer(handler.sourceMap)).toString('base64')

		flag = 'sourceMappingURL=data:application/json;base64,'
		handler.sourceMap = if handler.extBin == '.js'
			"\n//# #{flag}#{handler.sourceMap}\n"
		else
			"\n/*# #{flag}#{handler.sourceMap} */\n"

	###*
	 * Set the handler's source property.
	 * @private
	 * @param  {fileHandler} handler
	 * @return {Promise} Contains handler
	###
	getSrc = (handler) ->
		readfile = (path) ->
			handler.path = kit.path.resolve path
			handler.ext = kit.path.extname path

			kit.readFile path, handler.encoding
			.then (source) ->
				handler.source = source
				delete handler.content
				handler

		paths = handler.extSrc.map (el) -> handler.noExtPath + el
		checkSrc = ->
			path = paths.shift()
			return Promise.resolve() if not path
			kit.fileExists path
			.then (exists) ->
				if exists
					readfile path
				else
					checkSrc()

		checkSrc().then (ret) ->
			return ret if ret

			path = handler.noExtPath + handler.extBin
			kit.fileExists path
			.then (exists) ->
				if exists
					readfile path
				else
					err = new Error('File not exists: ' + path)
					err.name = 'fileNotExists'
					Promise.reject err

	###*
	 * Get the compiled code
	 * @private
	 * @param  {String}  extBin
	 * @param  {FileHandler}  cache
	 * @param  {Boolean} isCache
	 * @return {Promise} Contains the compiled content.
	###
	getCompiled = (extBin, handler, isCache = true) ->
		handler.lastExtBin = extBin

		# Direct return source file without compilation. Such as plain html or js.
		if extBin == handler.ext and not handler.forceCompile
			if opts.enableWatcher and isCache and not handler.deleted
				watchSrc handler
			Promise.resolve handler.source

		# If cached, return cache directly.
		else if handler.content
			Promise.resolve handler.content

		# Recompile.
		else
			cacheFromFile(handler).then (contentCache) ->
				if contentCache != undefined
					return contentCache

				try
					handler.compiler handler.source, handler.path, handler.data
				catch err
					Promise.reject err
			.then (content) ->
				handler.content = content

				if handler.sourceMap
					setSourceMap handler

				delete handler.error
			.catch (err) ->
				if _.isString err
					err = new Error(err)
				emit self.e.compileError, relate(handler.path), err
				err.name = self.e.compileError
				handler.error = err
			.then ->
				if opts.enableWatcher and isCache and not handler.deleted
					watchSrc handler

				if handler.error
					Promise.reject handler.error
				else
					self.emit.call(
						self
						self.e.compiled
						handler.path
						handler.content
						handler
					)
					Promise.resolve handler.content

	###*
	 * Get the compiled source code from file system.
	 * For a better restart performance.
	 * @private
	 * @param  {FileHandler} handler
	 * @return {Promise}
	###
	cacheFromFile = (handler) ->
		return Promise.resolve() if not handler.enableFileCache

		handler.fileCachePath = kit.path.join(
			self.opts.cacheDir
			jhash.hash(handler.path, true) + '-' + kit.path.basename(handler.path)
		)

		kit.readJSON handler.fileCachePath + '.json'
		.catch (err) ->
			Promise.reject new Error('cannotRead')
		.then (info) ->
			handler.cacheInfo = info
			Promise.all _(info.dependencies).keys().map(
				(path) ->
					kit.stat(path).then (stats) ->
						info.dependencies[path] >= stats.mtime.getTime()
			).value()
		.then (latestList) ->
			if _.all(latestList)
				handler.dependencyPaths = _.keys handler.cacheInfo.dependencies
				switch handler.cacheInfo.type
					when 'String'
						kit.readFile handler.fileCachePath, 'utf8'
					when 'Buffer'
						kit.readFile handler.fileCachePath
					else
						return
		.catch (err) ->
			return if err.message == 'cannotRead'
			kit.err err

	###*
	 * Save the compiled source code to file system.
	 * For a better restart performance.
	 * @private
	 * @param  {FileHandler} handler
	 * @return {Promise}
	###
	cacheToFile = (handler) ->
		return if not handler.enableFileCache

		switch handler.content.constructor.name
			when 'String', 'Buffer'
				content = handler.content
			else
				return

		cacheInfo = {
			type: content.constructor.name
			dependencies: {}
		}
		Promise.all [
			kit.outputFile handler.fileCachePath, content
			Promise.all(_.map(handler.watchedList, (v, path) ->
				kit.stat(path).then (stats) ->
					cacheInfo.dependencies[path] = stats.mtime.getTime()
			)).then ->
				kit.outputJson handler.fileCachePath + '.json', cacheInfo
		]

	###*
	 * Set handler cache.
	 * @param  {FileHandler} handler
	 * @return {Promise}
	###
	getCache = (handler) ->
		handler.compiler ?= (bin) -> bin

		cachedHandler = _.find cachePool, (v, k) ->
			for ext in handler.extSrc.concat(handler.extBin)
				if handler.noExtPath + ext == k
					return true
			return false

		if cachedHandler == undefined
			getSrc(handler).then (cachedHandler) ->
				cachePool[cachedHandler.path] = cachedHandler
				if _.keys(cachePool).length > opts.cacheLimit
					minHandler = _(cachePool).values().min('ctime').value()
					if minHandler
						self.releaseCache minHandler.path
				cachedHandler
		else
			if cachedHandler.error
				Promise.reject cachedHandler.error
			else
				Promise.resolve cachedHandler

	###*
	 * Generate a file handler.
	 * @param  {String} path
	 * @param  {FileHandler} handler
	 * @return {FileHandler}
	###
	genHandler = (path, handler) ->
		# TODO: This part is somehow too complex.

		extBin = kit.path.extname path

		if not handler
			if extBin == ''
				handler = _.find self.fileHandlers, (el) -> el.default
			else if self.fileHandlers[extBin]
				handler = self.fileHandlers[extBin]
				if self.fileHandlers[extBin].extSrc and
				extBin in self.fileHandlers[extBin].extSrc
					handler.forceCompile = true
			else
				handler = _.find self.fileHandlers, (el) ->
					el.extSrc and extBin in el.extSrc

		if handler
			handler = _.cloneDeep(handler)
			handler.key = kit.path.resolve path
			handler.ctime = Date.now() # Used for cacheLimit
			handler.cacheInfo = {}
			handler.dependencyPaths ?= []
			handler.watchedList = {}
			handler.extSrc ?= extBin
			handler.extSrc = [handler.extSrc] if _.isString(handler.extSrc)
			handler.extBin = extBin
			handler.encoding =
				if handler.encoding == undefined
					'utf8'
				else
					handler.encoding
			handler.dirname = kit.path.dirname(handler.key)
			handler.noExtPath = removeExt handler.key
			handler.enableFileCache ?= true
			if _.isString handler.compiler
				handler.compiler = self.fileHandlers[handler.compiler].compiler

			handler.opts = self.opts

		handler

	###*
	 * Watch the source file.
	 * @private
	 * @param  {fileHandler} handler
	###
	watchSrc = (handler) ->
		watcher = (path, curr, prev, isDeletion) ->
			# If moved or deleted
			if isDeletion
				self.releaseCache path
				emit(
					self.e.fileDeleted
					relate(path) + ' -> '.cyan + relate(handler.path)
				)

			else if curr.mtime != prev.mtime
				getSrc(handler)
				.then ->
					getCompiled handler.lastExtBin, handler
				.catch(->)
				.then ->
					emit(
						self.e.fileModified
						relate(path)
						handler.type or handler.extBin
						handler.reqPath
					)

		genWatchList(handler)
		.then ->
			return if _.keys(handler.newWatchList).length == 0

			Promise.all(_.map handler.newWatchList, (nil, path) ->
				return if _.isFunction(handler.watchedList[path])
				kit.watchFile path, watcher
				.then (listener) ->
					handler.watchedList[path] = listener
					emit self.e.watchFile, relate(path), handler.reqPath
			).then ->
				delete handler.newWatchList

				# Save the cached files.
				if handler.content
					cacheToFile handler

	# Parse the dependencies.
	getDependencies = (handler, currPaths) ->
		kit.parseDependency handler.path, {
			depReg: handler.dependencyReg
			depRoots: handler.dependencyRoots
			extensions: [handler.ext]
			handle: (path) ->
				path.replace(/^[\s'"]+/, '').replace(/[\s'";]+$/, '')
		}
		.then (paths) ->
			for p in paths
				handler.newWatchList[p] = null
			handler

	genWatchList = (handler) ->
		path = handler.path

		# Add the src file to watch list.
		if not _.isFunction(handler.watchedList[path])
			handler.watchedList[path] = null

		# Make sure the dependencyRoots is string.
		handler.dependencyRoots ?= []
		if handler.dependencyRoots.indexOf(handler.dirname) < 0
			handler.dependencyRoots.push handler.dirname

		handler.newWatchList = {}
		_.extend handler.newWatchList, handler.extraWatch
		handler.newWatchList[path] = handler.watchedList[path]

		for p in handler.dependencyPaths
			handler.newWatchList[p] = handler.watchedList[p]

		if handler.dependencyReg and not _.isRegExp(handler.dependencyReg)
			handler.dependencyReg = handler.dependencyReg[handler.ext]

		if handler.dependencyReg
			getDependencies handler
		else
			Promise.resolve()

	forceExt = (path, ext) ->
		removeExt(path) + ext

	removeExt = (path) ->
		path.replace /\.\w+$/, ''

module.exports = renderer
