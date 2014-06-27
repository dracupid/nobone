_ = require './_'
Q = require 'q'
os = require './os'
express = require 'express'
{ EventEmitter } = require 'events'

coffee = require 'coffee-script'
stylus = require 'stylus'
stylus_render = Q.denodeify stylus.render


class Renderer extends EventEmitter then constructor: ->

	super

	self = @

	self.code_handlers = [
		{
			pathless: null  # path tath without extension
			ext_src: '.coffee'
			ext_bin: '.js'
			compiler: (str) ->
				coffee.compile(str, { bare: true })
		}
		{
			pathless: null
			ext_src: '.styl'
			ext_bin: '.css'
			compiler: (str, path) ->
				stylus_render(str, { filename: path })
		}
		{
			pathless: null
			ext_src: '.ejs'
			ext_bin: ''
			compiler: (str, path) ->
				tpl = _.template str

				(data, opts) ->
					_.defaults data, {
						_
					}
					_.defaults opts, {
						sourceURL: path
					}

					tpl data, opts
		}
	]

	cache_pool = {}

	watch_file = (path, handler) ->
		self.emit 'watch_file', path

		os.watchFile(
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
			os.readFile(path, 'utf8')
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

	self.assets = (opts = {}) ->
		_.defaults opts, {
			root_dir: './assets'
		}

		static_handler = express.static opts.root_dir

		return (req, res, next) ->

			ext_bin = os.path.extname req.path
			pathless = os.path.join(
				opts.root_dir
				os.path.dirname(req.path)
				os.path.basename(req.path, ext_bin)
			)

			handler = _.find self.code_handlers, (el) -> el.ext_bin == ext_bin

			if handler
				handler.pathless = pathless

				get_cached(handler)
				.then (code) ->
					if typeof code == 'string'
						res.type ext_bin
						res.send code
					else
						self.emit 'compile_error', pathless + ext_bin, code
						res.send 500, code.toString()

				.catch (err) ->
					static_handler req, res, next
			else
				static_handler req, res, next

	self.ejs = (path) ->
		###
			The promise it return only produces a compiled function.
		###

		handler = self.code_handlers[2]
		handler.pathless = path.replace /(\.ejs)$/, ''
		get_cached handler


module.exports = Renderer