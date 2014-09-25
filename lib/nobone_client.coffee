# The NoBone helper for browser

class Nobone then constructor: (opts) ->
	'use strict'

	self = @


	self.lang_current = opts.lang_current
	self.lang_data = opts.lang_data

	init = ->
		if opts.auto_reload
			init_auto_reload()

	self.log = (msg, action = 'log') ->
		console[action] msg
		req = new XMLHttpRequest
		req.open 'POST', '/nobone-log'
		req.setRequestHeader 'Content-Type', 'application/json'
		req.send JSON.stringify(msg)

	self.lang = (cmd, lang = opts.lang_current) ->
		i = cmd.lastIndexOf '|'
		en = if i > -1 then cmd[...i] else cmd
		opts.lang_data[lang]?[cmd] or en

	init_auto_reload = ->
		es = new EventSource(opts.host + '/nobone-sse/auto_reload')

		es.addEventListener 'error', (e) ->
			console.warn(e.message)

		es.addEventListener 'file_modified', (e) ->
			msg = JSON.parse(e.data)

			console.log(">> file_modified: " + msg.req_path)

			reload_elem = (el, key) ->
				if '?' not in el[key]
					el[key] += '?nb_auto_reload=0'
				else
					if 'nb_auto_reload' in el[key]
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
						if msg.req_path in el.src
							location.reload()

				when '.css'
					each 'link', (el) ->
						if msg.req_path in el.href
							reload_elem el, 'href'

				when '.jpg', '.gif', '.png'
					each 'img', (el) ->
						if msg.req_path in el.src
							reload_elem el, 'src'

				else
					location.reload()

	init()
