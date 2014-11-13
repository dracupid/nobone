# The NoBone helper for browser

class Nobone then constructor: (opts) ->
	'use strict'

	self = @


	self.lang_current = opts.lang_current
	self.lang_set = opts.lang_set

	init = ->
		if opts.auto_reload
			init_auto_reload()

	self.log = (msg, action = 'log') ->
		console[action] msg
		req = new XMLHttpRequest
		req.open 'POST', '/nobone-log'
		req.setRequestHeader 'Content-Type', 'application/json'
		req.send JSON.stringify(msg)

	formatRegExp = /%[sdj%]/g
	self.format = (f) ->
		unless isString(f)
			objects = []
			i = 0

			while i < arguments.length
				objects.push inspect(arguments[i])
				i++
			return objects.join(" ")
		i = 1
		args = arguments
		len = args.length
		str = String(f).replace(formatRegExp, (x) ->
			return "%"  if x is "%%"
			return x  if i >= len
			switch x
				when "%s"
					String args[i++]
				when "%d"
					Number args[i++]
				when "%j"
					try
						return JSON.stringify(args[i++])
					catch _
						return "[Circular]"
				else
					x
			return
		)
		x = args[i]

		while i < len
			if isNull(x) or not isObject(x)
				str += " " + x
			else
				str += " " + inspect(x)
			x = args[++i]
		str

	self.lang = (cmd, args = [], name, lang_set) ->
		if args.constructor.name == 'String'
			lang_set = name
			name = args
			args = []

		name ?= self.lang_current
		lang_set ?= self.lang_set

		i = cmd.lastIndexOf '|'
		if i > -1
			key = cmd[...i]
			cat = cmd[i + 1 ..]
		else
			key = cmd

		set = lang_set[key]

		out = if set and set.constructor.name == 'Object'
			if set[name] == undefined
				key
			else
				if cat == undefined
					set[name]
				else if _.isObject set[name]
					set[name][cat]
				else
					key
		else if set and set.constructor.name == 'String'
		 	set
		else
			key

		if args.length > 0
			args.unshift out
			self.format.apply util, args
		else
			out

	self.lang_load = ->
		Object.defineProperty String.prototype, 'l', {
			get: -> self.lang this + ''
		}

		String.prototype.lang = (args...) ->
			args.unshift this + ''
			self.lang.apply null, args

	init_auto_reload = ->
		es = new EventSource(opts.host + '/nobone-sse/auto_reload')

		es.addEventListener 'error', (e) ->
			console.warn(e.message)

		es.addEventListener 'file_modified', (e) ->
			msg = JSON.parse(e.data)

			console.log(">> file_modified: " + msg.req_path)

			reload_elem = (el, key) ->
				if el[key].indexOf('?') == -1
					el[key] += '?nb_auto_reload=0'
				else
					if el[key].indexOf('nb_auto_reload') > -1
						el[key] = el[key].replace /nb_auto_reload=(\d+)/, (m, p) ->
							'nb_auto_reload=' + (+p + 1)
					else
						el[key] += '&nb_auto_reload=0'

				# Fix the Chrome renderer bug.
				body = document.body
				body.style.display = 'none'
				body.offsetHeight; # no need to store this anywhere, the reference is enough
				setTimeout ->
					body.style.display = 'block'
				, 50

			each = (qs, handler) ->
				elems = document.querySelectorAll(qs)
				[].slice.apply(elems).forEach(handler)

			if not msg.req_path
				location.reload()
				return

			switch msg.ext_bin
				when '.js'
					each 'script', (el) ->
						# Only reload the page if the page has included
						# the href.
						if el.src.indexOf(msg.req_path) > -1
							location.reload()

				when '.css'
					each 'link', (el) ->
						if el.href.indexOf(msg.req_path) > -1
							reload_elem el, 'href'

				when '.jpg', '.gif', '.png'
					each 'img', (el) ->
						if el.src.indexOf(msg.req_path) > -1
							reload_elem el, 'src'

				else
					location.reload()

	init()
