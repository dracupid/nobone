###*
 * It use the renderer module to create some handy functions.
 * @private
###

_ = require 'lodash'
kit = require '../kit'
{ Promise, fs } = kit

express = require 'express'

module.exports = {

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