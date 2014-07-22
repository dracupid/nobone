# The NoBone helper for browser

class Nobone then constructor: ->

	self = @

	init = ->
		init_auto_reload()

	self.log = (msg, action = 'log') ->
		console[action] msg
		req = new XMLHttpRequest
		req.open 'POST', '/nobone-log'
		req.setRequestHeader 'Content-Type', 'application/json'
		req.send JSON.stringify(msg)

	init_auto_reload = ->
		es = new EventSource('/nobone-sse/auto_reload')

		es.addEventListener 'error', (e) ->
			console.warn(e.message)

		es.addEventListener 'file_modified', (e) ->
			msg = JSON.parse(e.data)

			console.log(">> file_modified: " + msg.path)

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

			switch msg.ext_bin
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

window.nb = new Nobone
