_ = require 'lodash'
Q = require 'q'
kit = require '../kit'
express = require 'express'
{ EventEmitter } = require 'events'

###*
 * A abstract renderer for any string resources, such as template, source code, etc.
 * It automatically uses high performance memory cache.
 * You can run the benchmark to see the what differences it makes.
 * Even for huge project its memory usage is negligible.
 * @param {Object} opts Defaults:
 * ```coffee
 * {
 * 	enable_watcher: process.env.NODE_ENV == 'development'
 * 	code_handlers: {
 * 		'.html': {
 * 			default: true
 * 			ext_src: '.ejs'
 * 			type: 'html'
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.js': {
 * 			ext_src: '.coffee'
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.css': {
 * 			ext_src: '.styl'
 * 			compiler: (str, path) -> ...
 * 		}
 * 		'.mdx': {
 * 			ext_src: '.md'
 * 			type: 'html'
 * 			compiler: (str, path) -> ...
 * 		}
 * 	}
 * }```
 * @return {Renderer <- events.EventEmitter}
###
renderer = (opts) -> new Renderer(opts)

renderer.defaults = {
	enable_watcher: process.env.NODE_ENV == 'development'
	auto_log: true
	code_handlers: {
		'.html': {
			default: true    # Whether it is a default handler, optional.
			ext_src: '.ejs'
			type: 'html'	 # Force type, optional.
			###*
			 * The compiler should fulfil two interface.
			 * It should return a promise object. Only handles string.
			 * @param  {String} str Source code.
			 * @param  {String} path For debug info.
			 * @return {Any} Promise or any thing that contains the compiled code.
			###
			compiler: (str, path) ->
				ejs = kit.require 'ejs'
				tpl = ejs.compile str, { filename: path }

				(data = {}) ->
					_.defaults data, { _ }
					tpl data
		}
		'.js': {
			ext_src: '.coffee'
			compiler: (str, path) ->
				coffee = kit.require 'coffee-script'
				coffee.compile(str, { bare: true })
		}
		'.css': {
			ext_src: '.styl'
			compiler: (str, path) ->
				stylus = kit.require 'stylus'
				stylus_render = Q.denodeify stylus.render
				stylus_render(str, { filename: path })
		}
		'.mdx': {
			ext_src: '.md'
			type: 'html'
			compiler: (str, path) ->
				marked = kit.require 'marked'
				marked str
		}
	}
}


class Renderer extends EventEmitter then constructor: (opts = {}) ->

	super

	_.defaults opts, renderer.defaults

	self = @

	cache_pool = {}

	###*
	 * You can access all the code_handlers here.
	 * Manipulate them at runtime.
	 * @example
	 * ```coffee
	 * # We return js directly.
	 * renderer.code_handlers['.js'].compiler = (str) -> str
	 * ```
	 * @type {Object}
	###
	self.code_handlers = opts.code_handlers

	###*
	 * The cache pool of the result of `code_handlers.compiler`
	 * @type {Object} Key is the file path.
	###
	self.cache_pool = cache_pool

	###*
	 * Set a static directory.
	 * Static folder to automatically serve coffeescript and stylus.
	 * @param  {String | Object} opts If it's a string it represents the root_dir
	 * of this static directory. Defaults: `{ root_dir: '.' }`
	 * @return {Middleware} Experss.js middleware.
	###
	self.static = (opts = {}) ->
		if _.isString opts
			opts = { root_dir: opts }
		else
			_.defaults opts, {
				root_dir: '.'
			}

		static_handler = express.static opts.root_dir

		return (req, res, next) ->
			path = kit.path.join opts.root_dir, req.path

			rnext = -> static_handler req, res, next

			handler = get_handler path
			if handler
				get_cached(handler)
				.then (code) ->
					if code == null
						return res.send 500, 'compile_error'

					if code == undefined
						return rnext()

					res.type handler.type or handler.ext_bin

					switch typeof code
						when 'string'
							res.send code

						when 'function'
							res.send code()

						else
							throw new Error('unknown_code_type')

				.catch (err) ->
					if err.code == 'ENOENT' or err.code == 'EISDIR'
						rnext()
					else
						throw err
				.done()
			else
				rnext()

	###*
	 * Render a file. It will auto detect the file extension and
	 * choose the right compiler to handle the code.
	 * @param  {String} path The file path
	 * @return {Promise} Contains the compiled code.
	###
	self.render = (path) ->
		handler = get_handler path, true

		if handler
			get_cached handler
		else
			throw new Error('No matched code handler for:' + path)

	###*
	 * The browser javascript to support the auto page reload.
	 * You can use the socket.io event to custom you own.
	 * @return {String} Returns html.
	###
	self.auto_reload = ->
		Renderer.auto_reload

	###*
	 * Release the resources.
	###
	self.close = ->
		fs = kit.require 'fs'
		for k, v of cache_pool
			fs.unwatchFile(k)

	emit = ->
		self.emit.apply self, arguments

	get_code = (handler) ->
		pathless = handler.pathless
		path = pathless + handler.ext_src

		kit.readFile path, 'utf8'
		.then (str) ->
			handler.compiler(str, path)
		.then (code) ->
			cache_pool[path] = code
		.catch (err) ->
			if err.code == 'ENOENT' or err.code == 'EISDIR'
				alt_path = handler.pathless + handler.ext_bin
				kit.readFile alt_path, 'utf8'
				.then (code) ->
					path = alt_path
					cache_pool[path] = code
				.catch (err) ->
					throw err
			else
				if self.listeners('compile_error').length == 0
					kit.err '->\n' + err.toString().red
				else
					emit 'compile_error', path, err

				cache_pool[path] = null

	get_cached = (handler) ->
		path = null
		handler.compiler ?= (str) -> str

		pathless = handler.pathless
		path = pathless + handler.ext_src
		alt_path = pathless + handler.ext_bin

		if cache_pool[path] != undefined
			Q cache_pool[path]
		else if cache_pool[alt_path] != undefined
			Q cache_pool[alt_path]
		else
			if opts.enable_watcher
				Q.all([
					kit.is_file_exists path
					kit.is_file_exists alt_path
				]).then (rets) ->
					if rets[1]
						path = alt_path
					else if not rets[0]
						return

					emit 'watch_file', path
					kit.watch_file path, (path, curr, prev) ->
						# If moved or deleted
						if curr.dev == 0
							fs = kit.require 'fs'
							emit 'file_deleted', path
							delete cache_pool[path]
							fs.unwatchFile(path)
							return

						if curr.mtime != prev.mtime
							emit 'file_modified', path
							get_code(handler).done()

			get_code(handler)

	get_handler = (path, is_direct = false) ->
		ext_bin = kit.path.extname path

		if is_direct
			handler = _.find self.code_handlers, (el) -> el.ext_src == ext_bin
		else if ext_bin == ''
			handler = _.find self.code_handlers, (el) -> el.default
		else
			handler = self.code_handlers[ext_bin]

		if handler
			handler = _.clone(handler)
			handler.ext_bin = ext_bin
			handler.pathless = kit.path.join(
				kit.path.dirname(path)
				kit.path.basename(path, ext_bin)
			)
			handler
		else
			null

	Renderer.auto_reload = '''
		<!-- Auto reload page helper. -->
		<script type="text/javascript">
			if (!window.io) {
				document.write(unescape('%3Cscript%20src%3D%22/socket.io/socket.io.js%22%3E%3C/script%3E'));
			}
		</script>
		<script type="text/javascript">
			(function () {
				var sock = io();
				sock.on('file_modified', function (data) {
					console.log(">> Reload: " + data);
					location.reload();
				});
			})();
		</script>
	'''

module.exports = renderer
