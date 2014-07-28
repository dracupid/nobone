###*
 * A abstract renderer for any string resources, such as template, source content, etc.
 * It automatically uses high performance memory cache.
 * You can run the benchmark to see the what differences it makes.
 * Even for huge project its memory usage is negligible.
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

jhash = new kit.jhash.constructor

###*
 * Create a Renderer instance.
 * @param {Object} opts Example:
 * ```coffee
 * {
 * 	enable_watcher: process.env.NODE_ENV == 'development'
 * 	auto_log: process.env.NODE_ENV == 'development'
 *
 * 	# If renderer detect this pattern, it will auto inject `nobone_client.js`
 * 	# into the page.
 * 	inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
 * 	file_handlers: {
 * 		'.html': {
 * 			default: true
 * 			ext_src: '.ejs'
 * 			watch_list: {
 * 				'path': [pattern1, ...] # Extra files to watch.
 * 			}
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
 * }```
 * @return {Renderer}
###
renderer = (opts) -> new Renderer(opts)

renderer.defaults = {
	enable_watcher: process.env.NODE_ENV == 'development'
	auto_log: process.env.NODE_ENV == 'development'
	inject_client_reg: /<html[^<>]*>[\s\S]*<\/html>/i
	file_handlers: {
		'.html': {
			default: true    # Whether it is a default handler, optional.
			ext_src: ['.ejs']
			###*
			 * The compiler should fulfil two interface.
			 * It should return a promise object. Only handles string.
			 * @this {Renderer} The context of this function is the
			 * current renderer.
			 * @param  {String} str Source content.
			 * @param  {String} path For debug info.
			 * @param  {Any} data The data sent from the `render` function.
			 * when you call the `render` directly. Default is an empty object: `{ }`.
			 * @return {Any} Promise or any thing that contains the compiled content.
			###
			compiler: (str, path, data) ->
				self = @
				ejs = kit.require 'ejs'
				tpl = ejs.compile str, { filename: path }

				render = (data) ->
					_.defaults data, {
						_
						inject_client: process.env.NODE_ENV == 'development'
					}
					html = tpl data
					if data.inject_client and
					self.opts.inject_client_reg.test html
						html += nobone.client()
					html

				if _.isObject data
					render data
				else
					(data = {}) ->
						render data
		}
		'.js': {
			ext_src: '.coffee'
			compiler: (str, path, data = {}) ->
				coffee = kit.require 'coffee-script'
				coffee.compile(str, _.defaults(data, { bare: true }))
		}
		'.css': {
			ext_src: ['.styl', '.less']
			compiler: (str, path, data = {}) ->
				ext_src = kit.path.extname path
				if ext_src == '.styl'
					stylus = kit.require 'stylus'
					Q.ninvoke stylus, 'render', str, _.defaults(data, { filename: path })
				else
					try
						less = kit.require('less')
					catch e
						kit.err '"npm install less" first.'.red

					parser = new less.Parser(_.defaults data, { filename: path })
					Q.ninvoke(parser, 'parse', str)
					.then (tree) -> tree.toCSS()
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


class Renderer extends EventEmitter then constructor: (opts = {}) ->

	super

	_.defaults opts, renderer.defaults

	self = @

	self.opts = opts

	cache_pool = {}

	###*
	 * You can access all the file_handlers here.
	 * Manipulate them at runtime.
	 * @example
	 * ```coffee
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
	 * ```coffee
	 * {
	 * 	root_dir: '.'
	 * 	index: process.env.NODE_ENV == 'development' # Whether enable serve direcotry index.
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

			handler = get_handler path
			if handler
				handler.req_path = req_path
				get_cache(handler)
				.then (cache) ->
					if cache == null
						res.status 500
						return res.send self.e.compile_error

					content = cache.content

					res.type handler.type or handler.ext_bin

					switch content.constructor.name
						when 'String', 'Buffer'
							body = content
						when 'Function'
							body = content()
						else
							body = 'The compiler should produce a string or function: '.red +
								path.cyan
							err = new Error(body)
							err.name = 'unknown_type'
							throw err

					res.set 'ETag', cache.etag

					if opts.inject_client and
					res.get('Content-Type').indexOf('text/html;') == 0 and
					self.opts.inject_client_reg.test body
						body += nobone.client()

					res.send body
				.catch (err) ->
					if err.name == 'file_not_exists'
						rnext()
					else
						throw err
				.done()
			else
				rnext()

	###*
	 * Render a file. It will auto detect the file extension and
	 * choose the right compiler to handle the content.
	 * @param  {String} path The file path
	 * @param  {Any} data Extra data you want to send to the compiler.
	 * @param  {Boolean} is_cache Whether to cache the result,
	 * default is false.
	 * @return {Promise} Contains the compiled content.
	###
	self.render = (path, data, is_cache = true) ->
		handler = get_handler path, true

		if handler
			handler.data = data
			if is_cache
				get_cache(handler).then (cache) ->
					cache.content
			else
				compile handler, false
		else
			throw new Error('No matched content handler for:' + path)

	###*
	 * Release the resources.
	###
	self.close = ->
		for k, v of cache_pool
			fs.unwatchFile(k)

	self.e = {}

	###*
	 * @event compile_error
	 * @param {string} path The error file.
	 * @param {Error} err The error info.
	###
	self.e.compile_error = 'compile_error'

	###*
	 * @event watch_file
	 * @param {string} path The path of the file.
	 * @param {fs.Stats} curr Current state.
	 * @param {fs.Stats} prev Previous state.
	###
	self.e.watch_file = 'watch_file'

	###*
	 * @event file_deleted
	 * @param {string} path The path of the file.
	###
	self.e.file_deleted = 'file_deleted'

	###*
	 * @event file_modified
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

	compile = (handler, cache = true) ->
		Q.all handler.paths.map(kit.fileExists)
		.then (rets) ->
			ext_index = rets.indexOf(true)
			path = handler.paths[ext_index]
			if path
				ext = handler.ext_src[ext_index]
				encoding = if handler.encoding == undefined then 'utf8' else handler.encoding
				kit.readFile path, encoding
				.then (bin) ->
					if handler.type and handler.type != ext
						return handler.compiler.call self, bin, path, handler.data

					if ext == handler.ext_bin
						bin
					else
						handler.compiler.call self, bin, path, handler.data
				.then (content) ->
					if not cache
						return content

					if not _.isString content
						body = content.toString()
					else
						body = content
					hash = jhash.hash body
					len = body.length.toString(36)
					etag = "W/\"#{len}-#{hash}\""

					cache_pool[path] = { content, etag }
				.catch (err) ->
					emit self.e.compile_error, path, err
					cache_pool[path] = null
			else
				err = new Error('File not exists: ' + handler.pathless)
				err.name = 'file_not_exists'
				throw err

	get_cache = (handler) ->
		handler.compiler ?= (bin) -> bin

		cache = _.find cache_pool, (v, k) ->
			handler.paths.indexOf(k) > -1

		if cache
			return Q(cache)

		if opts.enable_watcher
			watch handler

		compile(handler)

	get_handler = (path, is_direct = false) ->
		ext_bin = kit.path.extname path

		if is_direct
			handler = _.find self.file_handlers, (el) ->
				el.ext_src == ext_bin or el.ext_src.indexOf(ext_bin) > -1
		else if ext_bin == ''
			handler = _.find self.file_handlers, (el) -> el.default
		else
			handler = self.file_handlers[ext_bin]

		if handler
			handler = _.cloneDeep(handler)
			handler.ext_src ?= ext_bin
			handler.ext_src = [handler.ext_src] if _.isString(handler.ext_src)
			handler.ext_bin = ext_bin
			handler.pathless = kit.path.join(
				kit.path.dirname(path)
				kit.path.basename(path, ext_bin)
			)
			if _.isString handler.compiler
				handler.compiler = self.file_handlers[handler.compiler].compiler

			if is_direct
				handler.ext_bin = ''
			else
				handler.ext_src.push handler.ext_bin
			handler.paths = handler.ext_src.map (el) ->
				handler.pathless + el

		handler

	watch = (handler) ->
		Q.all handler.paths.map(kit.fileExists)
		.then (rets) ->
			path = handler.paths[rets.indexOf(true)]
			return if not path

			emit self.e.watch_file, path, handler.req_path
			watcher = (path, curr, prev) ->
				# If moved or deleted
				if curr.mtime.getTime() == 0
					emit self.e.file_deleted, path
					delete cache_pool[path]
					fs.unwatchFile(path, watcher)

					# Extra watch_list
					if handler.watch_list and handler.watch_list[path]
						kit.glob handler.watch_list[path]
						.done (paths) ->
							for p in paths
								emit self.e.file_deleted, path + ' <- ' + p
								fs.unwatchFile(p, watcher)
					return

				if curr.mtime != prev.mtime
					emit(
						self.e.file_modified
						path
						handler.type or handler.ext_bin
						handler.req_path
					)
					compile(handler).done()

			kit.watch_file path, watcher

			# Extra watch_list
			if handler.watch_list and handler.watch_list[path]
				kit.watch_files handler.watch_list[path], watcher
				.done (paths) ->
					for p in paths
						emit self.e.watch_file, path + ' <- ' + p, handler.url

module.exports = renderer
