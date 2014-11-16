###*
 * It use the renderer module to create some handy functions.
###

_ = require 'lodash'
nobone = require '../nobone'
kit = require '../kit'
{ Promise, fs } = kit

express = require 'express'

module.exports = {
	gen_file_handlers: ->
		'.html':
			# Whether it is a default handler, optional.
			default: true
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

		'.js':
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

		'.jsb':
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

		'.css':
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

		'.md':
			type: '.html'
			ext_src: ['.md','.markdown']
			compiler: (str, path, data = {}) ->
				marked = kit.require 'marked'
				marked str, data

	__express: (path, opts, cb) ->
		@render path, opts
		.then (data) ->
			cb null, data
		.catch cb

	dir: (opts = {}) ->
		if _.isString opts
			opts = { root_dir: opts }

		_.defaults opts, {
			renderer: {}
			root_dir: '.'
		}

		renderer = require('./renderer')(opts.renderer)

		return (req, res, next) ->
			path = kit.path.join(opts.root_dir, req.path)
			kit.dirExists path
			.then (exists) ->
				if exists
					kit.readdir path
				else
					Promise.reject 'no dir found'
			.then (list) ->
				list.unshift '.'
				if req.path != '/'
					list.unshift '..'

				kit.async list.map (p) ->
					fp = kit.path.join opts.root_dir, req.path, p
					kit.stat(fp).then (stats) ->
						stats.is_dir = stats.isDirectory()
						if stats.is_dir
							stats.path = p + '/'
						else
							stats.path = p
						stats.ext = kit.path.extname p
						stats.size = stats.size
						stats
					.then (stats) ->
						if stats.is_dir
							kit.readdir(fp).then (list) ->
								stats.dir_count = list.length
								stats
						else
							stats
			.then (list) ->
				list.sort (a, b) -> a.path.localeCompare b.path

				list = _.groupBy list, (el) ->
					if el.is_dir
						'dirs'
					else
						'files'

				list.dirs ?= []
				list.files ?= []

				kit.async [
					renderer.render kit.path.join(__dirname, '../../assets/dir/index.html')
					renderer.render kit.path.join(__dirname, '../../assets/dir/default.css')
				]
				.then ([fn, css]) ->
					res.send fn({ list, css, path: req.path })
			.catch (err) ->
				kit.log err
				next()

	static: (opts = {}) ->
		self = @

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
			dir_handler = self.dir {
				root_dir: opts.root_dir
			}

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

}