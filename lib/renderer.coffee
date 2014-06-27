_ = require './_'
Q = require 'q'
kit = require './kit'
express = require 'express'
{ EventEmitter } = require 'events'

coffee = require 'coffee-script'
stylus = require 'stylus'
stylus_render = Q.denodeify stylus.render
ejs = require 'ejs'


class Renderer extends EventEmitter then constructor: ->

	super

	self = @

	self.code_handlers = {
		'.js': {
			ext_src: '.coffee'
			ext_bin: '.js'
			compiler: (str) ->
				coffee.compile(str, { bare: true })
		}
		'.css': {
			ext_src: '.styl'
			ext_bin: '.css'
			compiler: (str, path) ->
				stylus_render(str, { filename: path })
		}
		'.ejs': {
			ext_src: '.ejs'
			ext_bin: '.ejs'
			compiler: (str, path) ->
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
		'': {
			ext_src: '.ejs'
			ext_bin: ''
			compiler: (str, path) ->
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

	watch_file = (path, handler) ->
		self.emit 'watch_file', path

		kit.watchFile(
			path
			{ persistent: false, interval: 500 }
			(curr, prev) ->
				handler(path, curr, prev)
		)

	get_cached = (handler) ->
		path = null
		handler.compiler ?= (str) -> str

		path = handler.pathless + handler.ext_src

		get_code = ->
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

		if cache_pool[path] != undefined
			Q cache_pool[path]
		else
			get_code()
			.then (code) ->
				watch_file path, (path, curr, prev) ->
					if curr.mtime != prev.mtime
						self.emit 'file_modified', path
						get_code()

				return code

	get_handler = (path) ->
		ext_bin = kit.path.extname path

		handler = self.code_handlers[ext_bin]

		if handler
			handler.pathless = kit.path.join(
				kit.path.dirname(path)
				kit.path.basename(path, ext_bin)
			)
			handler
		else
			null

	self.assets = (opts = {}) ->
		_.defaults opts, {
			root_dir: './assets'
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


module.exports = -> new Renderer