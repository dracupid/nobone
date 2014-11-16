###*
 * An abstract renderer for any content, such as source code or image files.
 * It automatically uses high performance memory cache.
 * This renderer helps nobone to build a **passive compilation architecture**.
 * You can run the benchmark to see the what differences it makes.
 * Even for huge project the memory usage is negligible.
 * @extends {events.EventEmitter} [Ref](http://nodejs.org/api/events.html#events_class_events_eventemitter)
###
Overview = 'renderer'

_ = require 'lodash'
kit = require '../kit'
express = require 'express'
{ EventEmitter } = require 'events'
{ Promise, fs } = kit

renderer_widgets = require './renderer_widgets'

###*
 * Create a Renderer instance.
 * @param {Object} opts Defaults:
 * ```coffeescript
 * {
 * 	enable_watcher: kit.is_development()
 * 	auto_log: kit.is_development()
 *
 * 	# If renderer detects this pattern, it will auto-inject `nobone_client.js`
 * 	# into the page.
 * 	inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
 *
 * 	cache_dir: '.nobone/renderer_cache'
 * 	cache_limit: 1024

 * 	file_handlers: {
 * 		'.html': {
 * 			default: true
 * 			ext_src: ['.ejs', '.jade']
 * 			extra_watch: { path1: 'comment1', path2: 'comment2', ... } # Extra files to watch.
 * 			encoding: 'utf8' # optional, default is 'utf8'
 * 			dependency_reg: {
 * 				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/
 * 				'.jade': /^\s*(?:include|extends)\s+([^\r\n]+)/
 * 			}
 * 			compiler: (str, path, data) -> ...
 * 		}
 *
 * 		# Simple coffee compiler
 * 		'.js': {
 * 			ext_src: '.coffee'
 * 			compiler: (str, path) -> ...
 * 		}
 *
 * 		# Browserify a main entrance file.
 * 		'.jsb': {
 * 			type: '.js'
 * 			ext_src: '.coffee'
 * 			dependency_reg: /require\s+([^\r\n]+)/
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.css': {
 * 			ext_src: ['.styl', '.less', '.sass', '.scss']
 * 			dependency_reg: {
 *    			'.styl': /@(?:import|require)\s+([^\r\n]+)/
 * 				'.less': /@import\s*(?:\(\w+\))?\s*([^\r\n]+)/
 * 				'.sass': /@import\s+([^\r\n]+)/
 * 				'.scss': /@import\s+([^\r\n]+)/
 * 			}
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.md': {
 * 			type: 'html' # Force type, optional.
 * 			ext_src: ['.md', '.markdown']
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
		enable_watcher: kit.is_development()
		auto_log: kit.is_development()
		inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
		cache_dir: '.nobone/renderer_cache'
		cache_limit: 1024
		file_handlers: renderer_widgets.gen_file_handlers()
	}

	self = @

	self.opts = opts

	cache_pool = {}

	# Async lock, make sure one file won't be handled twice.
	render_queue = {}

	###*
	 * You can access all the file_handlers here.
	 * Manipulate them at runtime.
	 * @type {Object}
	 * @example
	 * ```coffeescript
	 * # We return js directly.
	 * renderer.file_handlers['.js'].compiler = (str) -> str
	 * ```
	###
	self.file_handlers = opts.file_handlers

	###*
	 * The cache pool of the result of `file_handlers.compiler`
	 * @type {Object} Key is the file path.
	###
	self.cache_pool = cache_pool

	# Express.js engine api.
	self.__express = (args...) ->
		renderer_widgets.apply self, args

	###*
	 * Set a service for listing directory content, similar with the `serve-index` project.
	 * @param  {String | Object} opts If it's a string it represents the root_dir.
	 * @return {Middleware} Experss.js middleware.
	###
	self.dir = renderer_widgets.dir

	###*
	 * Set a static directory proxy.
	 * Automatically compile, cache and serve source files for both deveopment and production.
	 * @param  {String | Object} opts If it's a string it represents the root_dir.
	 * of this static directory. Defaults:
	 * ```coffeescript
	 * {
	 * 	root_dir: '.'
	 *
	 * 	# Whether enable serve direcotry index.
	 * 	index: kit.is_development()
	 *
	 * 	inject_client: kit.is_development()
	 *
	 * 	# Useful when mapping a normal path to a hashed file.
	 * 	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
	 * 	req_path_handler: (path) ->
	 * 		decodeURIComponent path
	 * }
	 * ```
	 * @return {Middleware} Experss.js middleware.
	###
	self.static = (opts) ->
		renderer_widgets.static self, opts

	###*
	 * Render a file. It will auto-detect the file extension and
	 * choose the right compiler to handle the content.
	 * @param  {String | Object} path The file path. The path extension should be
	 * the same with the compiled result file. If it's an object, it can contain
	 * any number of following params.
	 * @param  {String} ext Force the extension. Optional.
	 * @param  {Object} data Extra data you want to send to the compiler. Optional.
	 * @param  {Boolean} is_cache Whether to cache the result,
	 * default is true. Optional.
	 * @param {String} req_path The http request path. Support it will make auto-reload
	 * more efficient.
	 * @return {Promise} Contains the compiled content.
	 * @example
	 * ```coffeescript
	 * # The 'a.ejs' file may not exists, it will auto-compile
	 * # the 'a.ejs' or 'a.html' to html.
	 * renderer.render('a.html').done (html) -> kit.log(html)
	 *
	 * # if the content of 'a.ejs' is '<% var a = 10 %><%= a %>'
	 * renderer.render('a.ejs', '.html').done (html) -> html == '10'
	 * renderer.render('a.ejs').done (str) -> str == '<% var a = 10 %><%= a %>'
	 * ```
	###
	self.render = (path, ext, data, is_cache, req_path) ->
		if _.isObject path
			{ path, ext, data, is_cache, req_path } = path

		if _.isString ext
			path = force_ext path, ext
		else if _.isBoolean ext
			req_path = data
			is_cache = ext
			data = undefined
		else if _.isObject ext
			{ ext, data, is_cache, req_path } = ext
		else
			[data, is_cache, req_path] = [ext, data, is_cache]

		is_cache ?= true

		handler = gen_handler path

		if handler
			# If current path is under processing, wait for it.
			if render_queue[handler.key]
				return render_queue[handler.key]

			handler.data = data
			handler.req_path = req_path
			p = if is_cache
				get_cache(handler)
			else
				get_src handler

			p = p.then (cache) ->
				get_compiled handler.ext_bin, cache, is_cache
			p.handler = handler

			# Release the lock when the compilation is done.
			p.catch(->).then -> delete render_queue[handler.key]

			render_queue[handler.key] = p
		else
			err = new Error('No matched content handler for:' + path)
			err.name = 'no_matched_handler'
			Promise.reject err

	###*
	 * Release the resources.
	###
	self.close = ->
		for path of cache_pool
			self.release_cache path

	###*
	 * Release memory cache of a file.
	 * @param  {String} path
	###
	self.release_cache = (path) ->
		handler = cache_pool[path]
		handler.deleted = true
		if handler.watched_list
			for wpath, watcher of handler.watched_list
				fs.unwatchFile(wpath, watcher)
		delete cache_pool[path]

	self.e = {}

	###*
	 * @event {compiled}
	 * @param {String} content Compiled content.
	 * @param {File_handler} handler The current file handler.
	###
	self.e.compiled = 'compiled'

	###*
	 * @event {compile_error}
	 * @param {String} path The error file.
	 * @param {Error} err The error info.
	###
	self.e.compile_error = 'compile_error'

	###*
	 * @event {watch_file}
	 * @param {String} path The path of the file.
	 * @param {fs.Stats} curr Current state.
	 * @param {fs.Stats} prev Previous state.
	###
	self.e.watch_file = 'watch_file'

	###*
	 * @event {file_deleted}
	 * @param {String} path The path of the file.
	###
	self.e.file_deleted = 'file_deleted'

	###*
	 * @event {file_modified}
	 * @param {String} path The path of the file.
	###
	self.e.file_modified = 'file_modified'

	relate = (p) ->
		rp = kit.path.relative process.cwd(), p

		m = rp.match(/\.\.\//g)
		if m and m.length > 3
			p
		else
			rp

	emit = (args...) ->
		if opts.auto_log
			if args[0] == 'compile_error'
				kit.err args[1].yellow + '\n' + (args[2] + '').red
			else
				kit.log [args[0].cyan].concat(args[1..]).join(' | '.grey)

		self.emit.apply self, args

	set_source_map = (handler) ->
		if _.isObject(handler.source_map)
			handler.source_map = JSON.stringify(handler.source_map)

		handler.source_map = (new Buffer(handler.source_map)).toString('base64')

		flag = 'sourceMappingURL=data:application/json;base64,'
		handler.source_map = if handler.ext_bin == '.js'
			"\n//# #{flag}#{handler.source_map}\n"
		else
			"\n/*# #{flag}#{handler.source_map} */\n"

	###*
	 * Set the handler's source property.
	 * @private
	 * @param  {file_handler} handler
	 * @return {Promise} Contains handler
	###
	get_src = (handler) ->
		readfile = (path) ->
			handler.path = kit.path.resolve path
			handler.ext = kit.path.extname path

			kit.readFile path, handler.encoding
			.then (source) ->
				handler.source = source
				delete handler.content
				handler

		paths = handler.ext_src.map (el) -> handler.no_ext_path + el
		check_src = ->
			path = paths.shift()
			return Promise.resolve() if not path
			kit.fileExists path
			.then (exists) ->
				if exists
					readfile path
				else
					check_src()

		check_src().then (ret) ->
			return ret if ret

			path = handler.no_ext_path + handler.ext_bin
			kit.fileExists path
			.then (exists) ->
				if exists
					readfile path
				else
					err = new Error('File not exists: ' + handler.no_ext_path)
					err.name = 'file_not_exists'
					Promise.reject err

	###*
	 * Get the compiled code
	 * @private
	 * @param  {String}  ext_bin
	 * @param  {File_handler}  cache
	 * @param  {Boolean} is_cache
	 * @return {Promise} Contains the compiled content.
	###
	get_compiled = (ext_bin, cache, is_cache = true) ->
		cache.last_ext_bin = ext_bin
		if ext_bin == cache.ext and not cache.force_compile
			if opts.enable_watcher and is_cache and not cache.deleted
				watch_src cache
			Promise.resolve cache.source
		else if cache.content
			Promise.resolve cache.content
		else
			cache_from_file(cache).then (content_cache) ->
				if content_cache
					return content_cache

				try
					cache.compiler cache.source, cache.path, cache.data
				catch err
					Promise.reject err
			.then (content) ->
				cache.content = content

				if cache.source_map
					set_source_map cache

				delete cache.error
			.catch (err) ->
				if _.isString err
					err = new Error(err)
				emit self.e.compile_error, relate(cache.path), err
				err.name = self.e.compile_error
				cache.error = err
			.then ->
				if opts.enable_watcher and is_cache and not cache.deleted
					watch_src cache

				if cache.error
					Promise.reject cache.error
				else
					self.emit.call self, self.e.compiled, cache.content, cache
					Promise.resolve cache.content

	###*
	 * Get the compiled source code from file system.
	 * For a better restart performance.
	 * @private
	 * @param  {File_handler} handler
	 * @return {Promise}
	###
	cache_from_file = (handler) ->
		handler.file_cache_path = kit.path.join(
			self.opts.cache_dir
			handler.path
		)

		kit.readJSON handler.file_cache_path + '.json'
		.then (info) ->
			handler.cache_info = info
			Promise.all _(info.dependencies).keys().map(
				(path) ->
					kit.stat(path).then (stats) ->
						info.dependencies[path] < stats.mtime.toJSON()
			).value()
		.then (outdate_list) ->
			if not _.any(outdate_list)
				switch info.type
					when 'String'
						kit.readFile handler.file_cache_path, 'utf8'
					when 'Buffer'
						kit.readFile handler.file_cache_path
					else
						return
		.catch(->)

	###*
	 * Save the compiled source code to file system.
	 * For a better restart performance.
	 * @private
	 * @param  {File_handler} handler
	 * @return {Promise}
	###
	cache_to_file = (handler) ->
		switch handler.content.constructor.name
			when 'String', 'Buffer'
				content = handler.content
			else
				return

		kit.outputFile handler.file_cache_path, handler.content

		cache_info = {
			type: handler.content.constructor.name
			dependencies: {}
		}
		Promise.all(_.map(handler.new_watch_list, (v, path) ->
			kit.stat(path).then (stats) ->
				cache_info.dependencies[path] = stats.mtime
		)).then ->
			kit.outputJson handler.file_cache_path + '.json', cache_info

	###*
	 * Set handler cache.
	 * @param  {File_handler} handler
	 * @return {Promise}
	###
	get_cache = (handler) ->
		handler.compiler ?= (bin) -> bin

		cache = _.find cache_pool, (v, k) ->
			for ext in handler.ext_src.concat(handler.ext_bin)
				if handler.no_ext_path + ext == k
					return true
			return false

		if cache == undefined
			get_src(handler).then (cache) ->
				cache_pool[cache.path] = cache
				if _.keys(cache_pool).length > opts.cache_limit
					min_handler = _(cache_pool).values().min('ctime').value()
					if min_handler
						self.release_cache min_handler.path
				cache
		else
			if cache.error
				Promise.reject cache.error
			else
				Promise.resolve cache

	###*
	 * Generate a file handler.
	 * @param  {String} path
	 * @return {File_handler}
	###
	gen_handler = (path) ->
		# TODO: This part is somehow too complex.

		ext_bin = kit.path.extname path

		if ext_bin == ''
			handler = _.find self.file_handlers, (el) -> el.default
		else if self.file_handlers[ext_bin]
			handler = self.file_handlers[ext_bin]
			if self.file_handlers[ext_bin].ext_src and
			ext_bin in self.file_handlers[ext_bin].ext_src
				handler.force_compile = true
		else
			handler = _.find self.file_handlers, (el) ->
				el.ext_src and ext_bin in el.ext_src

		if handler
			handler = _.cloneDeep(handler)
			handler.key = kit.path.resolve path
			handler.ctime = Date.now()
			handler.deps_list ?= []
			handler.watched_list = {}
			handler.ext_src ?= ext_bin
			handler.ext_src = [handler.ext_src] if _.isString(handler.ext_src)
			handler.ext_bin = ext_bin
			handler.encoding = if handler.encoding == undefined then 'utf8' else handler.encoding
			handler.dirname = kit.path.dirname(handler.key)
			handler.no_ext_path = remove_ext handler.key
			if _.isString handler.compiler
				handler.compiler = self.file_handlers[handler.compiler].compiler

			handler.opts = self.opts

		handler

	###*
	 * Watch the source file.
	 * @private
	 * @param  {file_handler} handler
	###
	watch_src = (handler) ->
		watcher = (path, curr, prev, is_deletion) ->
			# If moved or deleted
			if is_deletion
				self.release_cache path
				emit self.e.file_deleted, relate(path) + ' -> '.cyan + relate(handler.path)

			else if curr.mtime != prev.mtime
				get_src(handler)
				.then ->
					get_compiled handler.last_ext_bin, handler
				.catch(->)
				.then ->
					emit(
						self.e.file_modified
						relate(path)
						handler.type or handler.ext_bin
						handler.req_path
					)

		gen_watch_list(handler)
		.then ->
			return if _.keys(handler.new_watch_list).length == 0

			for path of handler.new_watch_list
				continue if _.isFunction(handler.watched_list[path])
				handler.watched_list[path] = kit.watch_file path, watcher
				emit self.e.watch_file, relate(path), handler.req_path

			# Save the cached files.
			if handler.content
				cache_to_file handler

			delete handler.new_watch_list

	# Parse the dependencies.
	get_dependencies = (handler, curr_paths) ->
		###
			Trim cases:
				"name"\s\s
				"name";\s\s
		###
		trim = (path) ->
			path
			.replace /^[\s'"]+/, ''
			.replace /[\s'";]+$/, ''

		gen_dep_paths = (matches) ->
			Promise.all matches.map (m) ->
				path = trim m.match(handler.dependency_reg)[1]
				unless kit.path.extname(path)
					path = path + handler.ext

				dep_paths = handler.dependency_roots.map (root) ->
					kit.path.join root, path

				get_dependencies handler, dep_paths

		reg = new RegExp(handler.dependency_reg.source, 'g')
		if curr_paths
			kit.glob curr_paths
			.then (paths) ->
				Promise.all paths.map (path) ->
					# Prevent the recycle dependencies.
					return if handler.new_watch_list[path]

					kit.readFile(path, 'utf8')
					.then (str) ->
						# The point to add path to watch list.
						handler.new_watch_list[path] = null

						matches = str.match reg
						return if not matches
						gen_dep_paths matches
			.catch(->)
		else
			return Promise.resolve() if not handler.source
			matches = handler.source.match reg
			return Promise.resolve() if not matches
			gen_dep_paths matches

	gen_watch_list = (handler) ->
		# Add the src file to watch list.
		if not _.isFunction(handler.watched_list[handler.path])
			handler.watched_list[handler.path] = null

		# Make sure the dependency_roots is string.
		handler.dependency_roots ?= []
		if handler.dependency_roots.indexOf(handler.dirname) < 0
			handler.dependency_roots.push handler.dirname

		handler.new_watch_list = {}
		_.extend handler.new_watch_list, handler.extra_watch
		handler.new_watch_list[handler.path] = handler.watched_list[handler.path]

		for p in handler.deps_list
			handler.new_watch_list[p] = handler.watched_list[p]

		if handler.dependency_reg and not _.isRegExp(handler.dependency_reg)
			handler.dependency_reg = handler.dependency_reg[handler.ext]

		if handler.dependency_reg
			get_dependencies handler
		else
			Promise.resolve()

	force_ext = (path, ext) ->
		remove_ext(path) + ext

	remove_ext = (path) ->
		path.replace /\.\w+$/, ''

module.exports = renderer
