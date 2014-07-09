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

			reload_elem = (el) ->
				el.outerHTML = el.outerHTML

			each = (qs, handler) ->
				elems = document.querySelectorAll(qs)
				[].slice.apply(elems).forEach(handler)

			switch msg.ext_bin
				when '.css'
					each('link[href*="' + msg.req_path + '"]', reload_elem)

				when '.jpg', '.gif', '.png'
					each('img[src*="' + msg.req_path + '"]', reload_elem)

				else
					location.reload()

	init()

window.nb = new Nobone
