_ = require 'lodash'
Q = require 'q'
kit = require './kit'
express = require 'express'
{ EventEmitter } = require 'events'


class Renderer extends EventEmitter then constructor: ->

	super

	self = @

	self.code_handlers = {
		'.js': {
			ext_src: '.coffee'
			compiler: (str) ->
				coffee = require 'coffee-script'
				coffee.compile(str, { bare: true })
		}
		'.css': {
			ext_src: '.styl'
			ext_bin: '.css'
			compiler: (str, path) ->
				stylus = require 'stylus'
				stylus_render = Q.denodeify stylus.render
				stylus_render(str, { filename: path })
		}
		'.ejs': {
			default: true    # Whether it is a default handler
			ext_src: '.ejs'
			compiler: (str, path) ->
				ejs = require 'ejs'
				tpl = ejs.compile str

				(data, opts) ->
					_.defaults data, {
						_
					}
					_.defaults opts, {
						sourceURL: path
					}

					tpl data, opts
		}
	}

	cache_pool = {}

	self.static = (opts = {}) ->
		_.defaults opts, {
			root_dir: '.'
		}

		static_handler = express.static opts.root_dir

		return (req, res, next) ->

			path = kit.path.join opts.root_dir, req.path
			handler = get_handler path

			if handler
				get_cached(handler)
				.then (code) ->
					if typeof code == 'string'
						res.type handler.ext_bin
						res.send code
					else
						self.emit 'compile_error', path, code
						res.send 500, code.toString()

				.catch (err) ->
					static_handler req, res, next
			else
				static_handler req, res, next

	self.render = (path) ->
		###
			Return a promise.
		###

		handler = get_handler path
		get_cached handler

	get_code = (handler) ->
		path = handler.pathless + handler.ext_src

		kit.readFile(path, 'utf8')
		.then (str) ->
			handler.compiler(str, path)
		.catch (err) ->
			if err.code == 'ENOENT'
				throw err
			else
				err
		.then (code) ->
			cache_pool[path] = code

	get_cached = (handler) ->
		path = null
		handler.compiler ?= (str) -> str

		path = handler.pathless + handler.ext_src

		if cache_pool[path] != undefined
			Q cache_pool[path]
		else
			get_code(handler)
			.then (code) ->
				if process.env.NODE_ENV == 'development'
					self.emit 'watch_file', path
					kit.watch_file path, (path, curr, prev) ->
						if curr.mtime != prev.mtime
							self.emit 'file_modified', path
							get_code(handler)

				return code

	get_handler = (path) ->
		ext_bin = kit.path.extname path

		if ext_bin == ''
			handler = _.find self.code_handlers, (el) -> el.default
		else
			handler = self.code_handlers[ext_bin]

		if handler
			handler.ext_bin = ext_bin
			handler.pathless = kit.path.join(
				kit.path.dirname(path)
				kit.path.basename(path, ext_bin)
			)
			handler
		else
			null


module.exports = -> new Renderer