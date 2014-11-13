window.onload = ->
	nb.lang_load()
	elem = document.createElement 'h1'
	elem.textContent = 'test'.l
	document.body.appendChild elem
