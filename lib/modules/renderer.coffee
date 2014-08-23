###*
 * A abstract renderer for any content, such as source code or image files.
 * It automatically uses high performance memory cache.
 * This renderer helps nobone to build a **passive compilation architecture**.
 * You can run the benchmark to see the what differences it makes.
 * Even for huge project the memory usage is negligible.
 * @extends {events.EventEmitter} [Ref](http://nodejs.org/api/events.html#events_class_events_eventemitter)
###
Overview = 'renderer'

_ = require 'lodash'
Q = require 'q'
nobone = require '../nobone'
kit = nobone.kit
express = require 'express'
{ EventEmitter } = require 'events'
fs = kit.require 'fs'

###*
 * Create a Renderer instance.
 * @param {Object} opts Defaults:
 * ```coffeescript
 * {
 * 	enable_watcher: process.env.NODE_ENV == 'development'
 * 	auto_log: process.env.NODE_ENV == 'development'
 *
 * 	# If renderer detects this pattern, it will auto-inject `nobone_client.js`
 * 	# into the page.
 * 	inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
 * 	file_handlers: {
 * 		'.html': {
 * 			default: true
 * 			ext_src: ['.ejs', '.jade']
 * 			watch_list: { path1: 'comment1', path2: 'comment2', ... } # Extra files to watch.
 * 			encoding: 'utf8' # optional, default is 'utf8'
 * 			compiler: (str, path, ext_src, data) -> ...
 * 		}
 * 		'.js': {
 * 			ext_src: '.coffee'
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.css': {
 * 			ext_src: ['.styl', '.less']
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.md': {
 * 			type: 'html' # Force type, optional.
 * 			ext_src: ['.md', '.markdown']
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.jpg': {
 * 			encoding: null # To use buffer.
 * 			compiler: (buf) -> buf
 * 		}
 * 		'.png': {
 * 			encoding: null # To use buffer.
 * 			compiler: '.jpg' # Use the compiler of '.jpg'
 * 		}
 * 		'.gif' ...
 * 	}
 * }
 * ```
 * @return {Renderer}
###
renderer = (opts) -> new Renderer(opts)


class Renderer extends EventEmitter then constructor: (opts = {}) ->

	super

	_.defaults opts, {
		enable_watcher: process.env.NODE_ENV == 'development'
		auto_log: process.env.NODE_ENV == 'development'
		inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
		file_handlers: {
			'.html': {
				default: true    # Whether it is a default handler, optional.
				ext_src: ['.ejs', '.jade']
				###*
				 * The compiler can handle any type of file.
				 * @this {File_handler} It has a extra property `opts` which is the
				 * options of the current renderer.
				 * If you need source map support, the `source_map`property
				 * must be set during the compile process.
				 * @param  {String} str Source content.
				 * @param  {String} path For debug info.
				 * @param  {Any} data The data sent from the `render` function.
				 * when you call the `render` directly. Default is an object:
				 * ```coffeescript
				 * {
				 * 	_: lodash
				 * 	inject_client: process.env.NODE_ENV == 'development'
				 * }
				 * ```
				 * @return {Promise} Promise that contains the compiled content.
				###
				compiler: (str, path, data) ->
					self = @
					switch @ext
						when '.ejs'
							@dependency_reg = /^<%[\n\r\s]*include\s+['"]?([^'"]+)['"]?[\n\r\s]%>/
							compiler = kit.require 'ejs'
						when '.jade'
							@dependency_reg = /^\s*(?:include|extends)\s+(.+)/
							try
								compiler = kit.require 'jade'
							catch e
								kit.err '"npm install jade" first.'.red
								process.exit()
					tpl_fn = compiler.compile str, { filename: path }

					render = (data) ->
						_.defaults data, {
							_
							inject_client: process.env.NODE_ENV == 'development'
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
						compress: process.env.NODE_ENV == 'production'
						compress_opts: { fromString: true }
					})
					if data.compress
						ug = kit.require 'uglify-js'
						ug.minify(code, data.compress_opts).code
					else
						code
			}
			'.css': {
				ext_src: ['.styl', '.less', '.sass', '.scss']
				compiler: (str, path, data = {}) ->
					_.defaults data, {
						filename: path
						compress: process.env.NODE_ENV == 'production'
					}
					switch @ext
						when '.styl'
							@dependency_reg = /^\s*(?:@import|@require)\s+['"]?([^'"]+)['"]?/
							stylus = kit.require 'stylus'
							Q.ninvoke stylus, 'render', str, data

						when '.less'
							@dependency_reg = /^\s*@import\s+['"]([^'"]+)['"]/
							try
								less = kit.require('less')
							catch e
								kit.err '"npm install less" first.'.red
								process.exit()

							parser = new less.Parser(data)
							Q.ninvoke(parser, 'parse', str)
							.then (tree) -> tree.toCSS data

						when '.sass', '.scss'
							@dependency_reg = /^\s*@import\s+['"]?([^'"]+)['"]?/
							try
								sass = kit.require 'node-sass'
							catch e
								kit.err '"npm install node-sass" first.'.red
								process.exit()
							sass.renderSync _.defaults data, {
								data: str
								includePaths: [kit.path.dirname path]
							}
			}
			'.md': {
				type: 'html' # Force type, optional.
				ext_src: ['.md','.markdown']
				compiler: (str, path, data = {}) ->
					marked = kit.require 'marked'
					marked str, data
			}
			'.jpg': {
				encoding: null # To use buffer.
				compiler: (buf) -> buf
			}
			'.png': {
				encoding: null
				compiler: '.jpg'
			}
			'.gif': {
				encoding: null
				compiler: '.jpg'
			}
		}
	}

	self = @

	self.opts = opts

	cache_pool = {}

	###*
	 * You can access all the file_handlers here.
	 * Manipulate them at runtime.
	 * @example
	 * ```coffeescript
	 * # We return js directly.
	 * renderer.file_handlers['.js'].compiler = (str) -> str
	 * ```
	 * @type {Object}
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
	 * Set a static directory.
	 * Static folder to automatically serve coffeescript and stylus.
	 * @param  {String | Object} opts If it's a string it represents the root_dir
	 * of this static directory. Defaults:
	 * ```coffeescript
	 * {
	 * 	root_dir: '.'
	 * 	index: process.env.NODE_ENV == 'development' # Whether enable serve direcotry index.
	 * 	inject_client: process.env.NODE_ENV == 'development'
	 * }
	 * ```
	 * @return {Middleware} Experss.js middleware.
	###
	self.static = (opts = {}) ->
		if _.isString opts
			opts = { root_dir: opts }

		_.defaults opts, {
			root_dir: '.'
			index: process.env.NODE_ENV == 'development'
			inject_client: process.env.NODE_ENV == 'development'
		}

		static_handler = express.static opts.root_dir
		if opts.index
			dir_handler = kit.require('serve-index')(
				kit.fs.realpathSync opts.root_dir
				{ icons: true, view: 'details' }
			)

		return (req, res, next) ->
			req_path = decodeURIComponent(req.path)
			path = kit.path.join opts.root_dir, req_path

			rnext = -> static_handler req, res, (err) ->
				if dir_handler
					dir_handler req, res, next
				else
					next err

			handler = gen_handler path
			if handler
				handler.req_path = req_path
				get_cache(handler)
				.then (cache) ->
					res.type handler.type or handler.ext_bin

					content = get_content handler, cache

					switch content.constructor.name
						when 'Number'
							body = content.toString()
						when 'String', 'Buffer'
							body = content
						when 'Function'
							body = content()
						else
							if cache.source_map
								if handler.is_source_map
									body = cache.source_map
								else
									source_map_comment = "sourceMappingURL=#{handler.req_path}.map"
									if handler.ext_bin == '.js'
										source_map_comment = "\n//# #{source_map_comment}\n"
									else
										source_map_comment = "\n/*# #{source_map_comment} */\n"
									body = content + source_map_comment
							else
								body = 'The compiler should produce a number, string, buffer or function: '.red +
									path.cyan + '\n' + kit.inspect(content).yellow
								err = new Error(body)
								err.name = 'unknown_type'
								throw err

					if opts.inject_client and
					res.get('Content-Type').indexOf('text/html;') == 0 and
					self.opts.inject_client_reg.test body and
					body.indexOf(nobone.client()) == -1
						body += nobone.client()

					res.send body
				.catch (err) ->
					switch err.name
						when self.e.compile_error
							res.status(500).end self.e.compile_error
						when 'file_not_exists'
							next()
						else
							throw err
				.done()
			else
				rnext()

	###*
	 * Render a file. It will auto-detect the file extension and
	 * choose the right compiler to handle the content.
	 * @param  {String} path The file path. The path extension should be
	 * the same with the compiled result file.
	 * @example
	 * ```coffeescript
	 * # The 'a.ejs' file may not exists, it will auto-compile
	 * # the 'a.ejs' or 'a.html' to html.
	 * renderer.render('a.html').done (html) -> kit.log(html)
	 * ```
	 * @param  {String} ext Force the extension. Optional.
	 * @example
	 * ```coffeescript
	 * # if the content of 'a.ejs' is '<% var a = 10 %><%= a %>'
	 * renderer.render('a.ejs', '.html').done (html) -> html == '10'
	 * renderer.render('a.ejs').done (str) -> str == '<% var a = 10 %><%= a %>'
	 * ```
	 * @param  {Object} data Extra data you want to send to the compiler. Optional.
	 * @param  {Boolean} is_cache Whether to cache the result,
	 * default is true. Optional.
	 * @return {Promise} Contains the compiled content.
	###
	self.render = (path, ext, data, is_cache) ->
		if _.isString ext
			path = path[...-kit.path.extname(path).length] + ext
		else if _.isBoolean ext
			is_cache = ext
			data = undefined
		else
			[data, is_cache] = [ext, data]

		is_cache ?= true

		handler = gen_handler path

		if handler
			handler.data = data
			if is_cache
				p = get_cache(handler)
			else
				p = hcompile handler, false
			p.then (cache) ->
				get_content handler, cache
		else
			throw new Error('No matched content handler for:' + path)

	###*
	 * Release the resources.
	###
	self.close = ->
		for path, handler of cache_pool
			for wpath, watcher of handler.watch_list
				fs.unwatchFile(wpath, watcher)
			delete cache_pool[path]

	self.e = {}

	###*
	 * @event {compile_error}
	 * @param {string} path The error file.
	 * @param {Error} err The error info.
	###
	self.e.compile_error = 'compile_error'

	###*
	 * @event {watch_file}
	 * @param {string} path The path of the file.
	 * @param {fs.Stats} curr Current state.
	 * @param {fs.Stats} prev Previous state.
	###
	self.e.watch_file = 'watch_file'

	###*
	 * @event {file_deleted}
	 * @param {string} path The path of the file.
	###
	self.e.file_deleted = 'file_deleted'

	###*
	 * @event {file_modified}
	 * @param {string} path The path of the file.
	###
	self.e.file_modified = 'file_modified'

	emit = ->
		if opts.auto_log
			name = arguments[0]
			if name == 'compile_error'
				kit.err arguments[1].yellow + '\n' + arguments[2].toString().red
			else
				kit.log "#{name}: ".cyan + (_.toArray arguments)[1..].join(' | ')

		self.emit.apply self, arguments

	hcompile = (handler, is_cache = true) ->
		compile_src = (path) ->
			handler.path = path
			kit.readFile path, handler.encoding
			.then (source) ->
				handler.source = source
				handler.ext = kit.path.extname path
				handler.compiler source, path, handler.data
			.then (content) ->
				handler.content = content
				delete handler.error
			.catch (err) ->
				emit self.e.compile_error, path, err.stack
				err.name = self.e.compile_error
				handler.error = err
			.then ->
				if is_cache
					cache_pool[path] = handler
				if handler.error
					throw handler.error
				handler

		paths = _.clone handler.paths
		check_src = ->
			path = paths.shift()
			return Q() if not path
			kit.fileExists path
			.then (exists) ->
				if exists
					compile_src path
				else
					check_src()

		check_src().then (ret) ->
			return ret if ret

			path = handler.pathless + handler.ext_bin
			kit.fileExists path
			.then (exists) ->
				if exists
					handler.path = path
					handler.ext = handler.ext_bin
					kit.readFile path, handler.encoding
					.then (source) ->
						handler.source = source
						handler
				else
					err = new Error('File not exists: ' + handler.pathless)
					err.name = 'file_not_exists'
					throw err

	get_content = (handler, cache) ->
		if cache.content == undefined
			cache.source
		else if handler.ext_bin == cache.ext
			cache.source
		else
			cache.content

	get_cache = (handler) ->
		handler.compiler ?= (bin) -> bin

		cache = _.find cache_pool, (v, k) ->
			handler.paths.indexOf(k) > -1

		if cache == undefined
			compiled = hcompile(handler)

			if opts.enable_watcher
				compiled.fin -> watch handler

			compiled
		else
			Q.fcall ->
				if cache.error
					throw cache.error
				else
					cache

	gen_handler = (path) ->
		# TODO: This part is somehow to complex.

		ext_bin = kit.path.extname path

		if ext_bin == '.map'
			path = kit.path.join(
				kit.path.dirname(path)
				kit.path.basename(path, ext_bin)
			)
			ext_bin = kit.path.extname path
			is_source_map = true

		if ext_bin == ''
			handler = _.find self.file_handlers, (el) -> el.default
		else if self.file_handlers[ext_bin]
			handler = self.file_handlers[ext_bin]
		else
			handler = _.find self.file_handlers, (el) ->
				el.ext_src and el.ext_src.indexOf(ext_bin) > -1

		if handler
			handler = _.cloneDeep(handler)
			handler.ctime = Date.now()
			handler.is_source_map = is_source_map
			handler.watch_list ?= {}
			handler.ext_src ?= ext_bin
			handler.ext_src = [handler.ext_src] if _.isString(handler.ext_src)
			handler.ext_bin = ext_bin
			handler.encoding = if handler.encoding == undefined then 'utf8' else handler.encoding
			handler.dirname = kit.path.dirname(path)
			handler.pathless = kit.path.join(
				handler.dirname
				kit.path.basename(path, ext_bin)
			)
			if _.isString handler.compiler
				handler.compiler = self.file_handlers[handler.compiler].compiler

			handler.paths = handler.ext_src.map (el) ->
				handler.pathless + el

			handler.opts = self.opts

		handler

	watch = (handler) ->
		# async lock, make sure one file won't be watched twice.
		watch.processing ?= []

		watcher = (path, curr, prev, is_deletion) ->
			# If moved or deleted
			if is_deletion
				delete cache_pool[path]
				emit self.e.file_deleted, path + ' -> '.cyan + handler.path

			else if curr.mtime != prev.mtime
				hcompile(handler).fin ->
					emit(
						self.e.file_modified
						path
						handler.type or handler.ext_bin
						handler.req_path
					)

		Q.fcall ->
			gen_watch_list(handler)
		.then ->
			return if _.keys(handler.watch_list).length == 0

			for path of handler.watch_list
				handler.watch_list[path] = kit.watch_file path, watcher
				emit self.e.watch_file, path, handler.req_path
				_.remove watch.processing, (el) -> el == path
		.done()

	force_ext = (path, ext) ->
		kit.path.join(
			kit.path.dirname path
			kit.path.basename path, ext
		) + ext

	get_dependencies = (handler, curr_path) ->
		reg = new RegExp(handler.dependency_reg.source, 'g')
		if curr_path
			kit.readFile(curr_path, 'utf8')
			.then (str) ->
				handler.watch_list[curr_path] = null
				matches = str.match reg
				return if not matches
				Q.all matches.map (m) ->
					path = m.match(handler.dependency_reg)[1]
					dep_path = kit.path.join(handler.dirname, force_ext(path, handler.ext))
					get_dependencies handler, dep_path
			.catch -> return
		else
			return Q() if not handler.source
			matches = handler.source.match reg
			return Q() if not matches
			Q.all matches.map (m) ->
				path = m.match(handler.dependency_reg)[1]
				dep_path = kit.path.join(handler.dirname, force_ext(path, handler.ext))
				get_dependencies handler, dep_path

	# Parse the dependencies.
	gen_watch_list = (handler) ->
		return if not handler.path
		handler.ext = kit.path.extname handler.path

		if watch.processing.indexOf(handler.path) > -1
			_.remove paths, (el) -> el == handler.path
		else
			watch.processing.push handler.path
			handler.watch_list[handler.path] = null

		if handler.dependency_reg
			get_dependencies handler

module.exports = renderer
