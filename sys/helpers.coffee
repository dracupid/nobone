

# Dump error information.
_.mixin

	u: ->
		###
			url prefix
		###
		NB.conf.url_prefix

	sandbox: (func, err_msg) ->
		try
			func()
		catch e
			_.log "\u0007\n", 'error' # Bell sound
			_.log """>> #{err_msg}
				>> #{e}
				>> Stack: #{e.stack}
			""".c('red'), 'error'
			if e.location
				_.log JSON.stringify(e, null, 4).c('red'), 'error'
			_.log "<<".c('red'), 'error'

	safe_extend: (objs...) ->
		###
			Check if list of objects have same named properties.
		###

		key_arrs = ( _.keys(arr) for arr in objs )

		inter = _.intersection.apply(_, key_arrs)

		if inter.length > 0
			throw ('Some properties are same named: ' + inter).red
		else
			return _.extend.apply(_, objs)

	node_version: ->
		###
			Return a int represent the version of node.
		###

		arr = process.version.slice(1).split('.')
		v = +arr[0] * 10000 + +arr[1] * 100 + +arr[2]
		return v

	get_cached_code: (path, compiler) ->
		###
			compiler: (str) ->
				return the compiled code.
		###

		NB.code_cache_pool ?= {}

		if NB.code_cache_pool[path] != undefined
			return NB.code_cache_pool[path]

		get_code = =>
			_.sandbox(
				->
					fs = require 'fs-extra'
					str = fs.readFileSync(path, 'utf8')

					is_first_load = !NB.code_cache_pool[path]

					if compiler
						NB.code_cache_pool[path] = compiler str, path
					else
						NB.code_cache_pool[path] = str

					if !is_first_load
						NB.nobone.emitter.emit 'code_reload', path
						_.log (">> Reload: " + path).c('green')
				"Load error: " + path
			)

		get_code()

		if NB.conf.mode != 'production'
			Gaze = require 'gaze'

			gaze = new Gaze(path)
			gaze.on('changed', get_code)
			gaze.on('deleted', =>
				delete NB.code_cache_pool[path]
				gaze.remove(path)
				_.log ">> Watch removed: #{path}".c('yellow')
			)
			_.log (">> Watch: " + path).c('green')

		return NB.code_cache_pool[path]

	sync_run_tasks: (tasks, all_done) ->
		i = 0

		check = ->
			if i < tasks.length
				run()
			else
				all_done()

		run = ->
			tasks[i](check, i)
			i++

		check()

	async_run_tasks: (tasks, all_done) ->
		count = 0

		check = ->
			if count < _.keys(tasks).length
				count++
			else
				all_done?()

		check()

		_.each(tasks, (task, k) ->
			task(check, k)
		)

	log: (msg, method = 'log') ->
		if NB.conf.log_to_std
			console[method] '[' + Date.now() + ']' + msg

		NB.nobone.emitter.emit 'log', msg, method

	l: (english) ->
		###
			Translate English to current language.
		###

		str = NB.langs[NB.conf.current_lang][english]
		return str or english

	js: (list) =>
		# e.g. js('main.js', 'others.js', ...)
		if list instanceof Array
			arr = list
		else
			arr = arguments

		out = ''
		for path in arr
			out += "<script type='text/javascript' src='#{path}'></script>"

		return out

	css: (list) =>
		# e.g. css('main.css', 'others.css', ...)
		if list instanceof Array
			arr = list
		else
			arr = arguments

		out = ''
		for path in arr
			out += "<link rel='stylesheet' type='text/css' href='#{path}' />"

		return out


# Other helpers

	# String color getter only works on none-production mode.
	String.prototype.c = (color) ->
		if NB.conf.mode != 'production'
			return this[color]
		else
			return this + ''
