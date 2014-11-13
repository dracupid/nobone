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
nobone = require '../nobone'
kit = nobone.kit
express = require 'express'
{ EventEmitter } = require 'events'
{ Promise, fs } = kit

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
		file_handlers: {
			'.html': {
				default: true    # Whether it is a default handler, optional.
				ext_src: ['.ejs', '.jade']
				dependency_reg: {
					'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/
				}
				###*
				 * The compiler can handle any type of file.
				 * @context {File_handler} Properties:
				 * ```coffeescript
				 * {
				 * 	ext: String # The current file's extension.
				 * 	opts: Object # The current options of renderer.
				 *
				 * 	# The file dependencies of current file. If you set it in the `compiler`,
				 * 	# the `dependency_reg` and `dependency_roots` should be left undefined.
				 * 	deps_list: Array
				 *
				 * 	dependency_reg: RegExp # The regex to match dependency path. Regex or Table.
				 * 	dependency_roots: Array # The root directories for searching dependencies.
				 *
				 * 	# The source map informantion.
				 * 	# If you need source map support, the `source_map`property
				 * 	# must be set during the compile process. If you use inline source map,
				 * 	# this property shouldn't be set.
				 * 	source_map: String or Object
				 * }
				 * ```
				 * @param  {String} str Source content.
				 * @param  {String} path For debug info.
				 * @param  {Any} data The data sent from the `render` function.
				 * when you call the `render` directly. Default is an object:
				 * ```coffeescript
				 * {
				 * 	_: lodash
				 * 	inject_client: kit.is_development()
				 * }
				 * ```
				 * @return {Promise} Promise that contains the compiled content.
				###
				compiler: (str, path, data) ->
					self = @
					switch @ext
						when '.ejs'
							compiler = kit.require 'ejs'
							tpl_fn = compiler.compile str, { filename: path }
						when '.jade'
							try
								compiler = kit.require 'jade'
								tpl_fn = compiler.compile str, { filename: path }
								@deps_list = tpl_fn.dependencies
							catch e
								kit.err '"npm install jade" first.'.red
								process.exit()

					render = (data) ->
						_.defaults data, {
							_
							inject_client: kit.is_development()
						}
						html = tpl_fn data
						if data.inject_client and
						self.opts.inject_client_reg.test html
							html += nobone.client()
						html

					if _.isObject data
						render data
					else
						func = (data = {}) ->
							render data
						func.toString = -> str
						func
			}
			'.js': {
				ext_src: '.coffee'
				compiler: (str, path, data = {}) ->
					coffee = kit.require 'coffee-script'
					code = coffee.compile str, _.defaults(data, {
						bare: true
						compress: kit.is_production()
						compress_opts: { fromString: true }
					})
					if data.compress
						ug = kit.require 'uglify-js'
						ug.minify(code, data.compress_opts).code
					else
						code
			}
			'.jsb': {
				type: '.js'
				dependency_reg: /require\s+([^\r\n]+)/
				ext_src: '.coffee'
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
						compress: kit.is_production()
						compress_opts: { fromString: true }
						browserify:
							extensions: '.coffee'
							debug: kit.is_development()
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
					Promise.promisify(b.bundle, b)().then (code) ->
						if data.compress
							ug = kit.require 'uglify-js'
							ug.minify(code, data.compress_opts).code
						else
							code
				}
			'.css': {
				ext_src: ['.styl', '.less', '.sass', '.scss']
				dependency_reg: {
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
							stylus = kit.require 'stylus'
							_.defaults data, { sourcemap: { inline: kit.is_development() } }
							styl = stylus(str, data)
							@deps_list = styl.deps()
							Promise.promisify(styl.render, styl)()

						when '.less'
							try
								less = kit.require('less')
							catch e
								kit.err '"npm install less@1.7.5" first.'.red
								process.exit()

							parser = new less.Parser(_.defaults data, {
								sourceMapFileInline: kit.is_development()
								sourceMap: kit.is_development()
							})
							new Promise (resolve, reject) ->
								parser.parse str, (err, tree) ->
									if err
										kit.log err.stack
										# The error message of less is the worst.
										err.message = err.filename + ":#{err.line}:#{err.column}\n" + err.message
										reject err
									else
										self.deps_list = _.keys(parser.imports.files)
										resolve tree.toCSS(data)

						when '.sass', '.scss'
							try
								sass = kit.require 'node-sass'
							catch e
								kit.err '"npm install node-sass" first.'.red
								process.exit()
							sass.renderSync _.defaults data, {
								outputStyle: if kit.is_production() then 'compressed' else 'nested'
								file: path
								data: str
								includePaths: [kit.path.dirname(path)]
							}
			}
			'.md': {
				type: '.html'
				ext_src: ['.md','.markdown']
				compiler: (str, path, data = {}) ->
					marked = kit.require 'marked'
					marked str, data
			}
		}
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
	self.__express = (path, opts, fn) ->
		self.render path, opts
		.catch fn
		.done (str) ->
			fn null, str

	###*
	 * Set a static directory proxy.
	 * Automatically compile, cache and serve source files for both deveopment and production.
	 * @param  {String | Object} opts If it's a string it represents the root_dir
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
	self.static = (opts = {}) ->
		if _.isString opts
			opts = { root_dir: opts }

		_.defaults opts, {
			root_dir: '.'
			index: kit.is_development()
			inject_client: kit.is_development()
			req_path_handler: (path) -> decodeURIComponent path
		}

		static_handler = express.static opts.root_dir
		if opts.index
			dir_handler = kit.require('serve-index')(
				kit.fs.realpathSync opts.root_dir
				{ icons: true, view: 'details' }
			)

		return (req, res, next) ->
			req_path = opts.req_path_handler req.path
			path = kit.path.join opts.root_dir, req_path

			rnext = -> static_handler req, res, (err) ->
				if dir_handler
					dir_handler req, res, next
				else
					next err

			p = self.render path, true, req_path

			p.then (content) ->
				handler = p.handler
				res.type handler.type or handler.ext_bin

				switch content and content.constructor.name
					when 'Number'
						body = content.toString()
					when 'String', 'Buffer'
						body = content
					when 'Function'
						body = content()
					else
						body = 'The compiler should produce a number, string, buffer or function: '.red +
							path.cyan + '\n' + kit.inspect(content).yellow
						err = new Error(body)
						err.name = 'unknown_type'
						Promise.reject err

				if opts.inject_client and
				res.get('Content-Type').indexOf('text/html;') == 0 and
				self.opts.inject_client_reg.test(body) and
				body.indexOf(nobone.client()) == -1
					body += nobone.client()

				if handler.source_map
					body += handler.source_map

				res.send body
			.catch (err) ->
				switch err.name
					when self.e.compile_error
						res.status(500).end self.e.compile_error
					when 'file_not_exists', 'no_matched_handler'
						rnext()
					else
						Promise.reject err
			.done()

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
		else
			[data, is_cache, req_path] = [ext, data, is_cache]

		is_cache ?= true

		handler = gen_handler path

		if handler
			# If current path is under processing, wait for it.
			if render_queue[handler.path]
				return render_queue[handler.path]

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
			p.catch(->).then -> delete render_queue[handler.path]

			render_queue[handler.path] = p
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
		if p[0] == '/' or p[1...3] == ':\\'
			kit.path.relative process.cwd(), p

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
		pp = Promise.resolve()
		if ext_bin == cache.ext and not cache.force_compile
			if opts.enable_watcher and is_cache and not cache.deleted
				pp = watch cache
			pp.then -> cache.source
		else if cache.content
			pp.then -> cache.content
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
					pp = watch cache

				if cache.error
					Promise.reject cache.error
				else
					self.emit.call self, self.e.compiled, cache.content, cache
					pp.then -> cache.content

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
			handler.path = kit.path.resolve path
			handler.ctime = Date.now()
			handler.deps_list ?= []
			handler.watched_list = {}
			handler.ext_src ?= ext_bin
			handler.ext_src = [handler.ext_src] if _.isString(handler.ext_src)
			handler.ext_bin = ext_bin
			handler.encoding = if handler.encoding == undefined then 'utf8' else handler.encoding
			handler.dirname = kit.path.dirname(handler.path)
			handler.no_ext_path = remove_ext handler.path
			if _.isString handler.compiler
				handler.compiler = self.file_handlers[handler.compiler].compiler

			handler.opts = self.opts

		handler

	###*
	 * Watch the source file.
	 * @private
	 * @param  {file_handler} handler
	###
	watch = (handler) ->
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
