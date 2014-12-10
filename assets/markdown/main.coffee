do ->
	$ = (qs, self = document) ->
		self.querySelectorAll qs

	createDiv = (str) ->
		div = document.createElement 'div'
		div.innerHTML = str
		div

	space = (n) ->
		[0...n]
		.map -> '<b class="space">·</b>'
		.join ''

	format = (minH, h) ->
		tag = h.tagName
		n = +tag.match(/\d+/) - minH
		div = createDiv """
			#{space(n)}
			<#{tag}>
				#{h.textContent.trim()}
			</#{tag}>
		"""

		$(tag, div)[0].addEventListener 'click', ->
			h.scrollIntoView()

		div

	findPos = (obj) ->
		curtop = 0
		if obj.offsetParent
			while obj = obj.offsetParent
				curtop += obj.offsetTop
			curtop += obj.offsetTop
		return curtop

	createTOC = ->

		hList = []

		allH = $('h1, h2, h3, h4, h5, h6', $('#main')[0])
		minH = [].slice.apply(allH).reduce((m, el) ->
			n = +el.tagName.match(/h(\d)/i)[1]
			if m < n then m else n
		, 100)

		for el in allH
			if (m = el.tagName.match /h\d+/i)
				hList.push(format minH, el)

			if (m = el.tagName.match /ul/i)
				for el in $('h4', el)
					hList.push(format minH, el)

		toc = $('#toc')[0]
		content = $('.content', toc)[0]

		hList.forEach (el) -> content.appendChild el

		document.body.appendChild toc

		# If toc title clicked, toggle the visibility of toc.
		tocTitle = $('#toc > h1')[0]

		if localStorage.getItem('toc') == 'hide'
			toc.style.height = '60px'

		tocTitle.addEventListener 'click', ->
			if toc.style.height == '60px'
				toc.style.height = null
				localStorage.setItem 'toc', 'show'
			else
				localStorage.setItem 'toc', 'hide'
				toc.style.height = '60px'

	initSyntaxHighlight = ->
		[].slice.apply(document.querySelectorAll('pre code[class]')).forEach((el) ->
			lang = el.getAttribute('class').replace('lang-', '')
			brush = 'brush: ' + lang + ' highlight: ' + location.hash.replace('#L', '')
			el.parentElement.setAttribute('class', brush)
			el.parentElement.innerHTML = el.innerHTML
		)
		SyntaxHighlighter.defaults['toolbar'] = false
		SyntaxHighlighter.all()

		window.addEventListener('load', ->
			setTimeout ->
				document.querySelector('.highlighted')?.scrollIntoView()
			, 0
		)

	createTOC()

	initSyntaxHighlight()
