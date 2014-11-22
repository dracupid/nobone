
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

format = (h) ->
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

hList = []

allH = $('h1, h2, h3, h4, h5, h6', $('#main')[0])
minH = [].slice.apply(allH).reduce((m, el) ->
	n = +el.tagName.match(/h(\d)/i)[1]
	if m < n then m else n
, 100)

for el in allH
	if (m = el.tagName.match /h\d+/i)
		hList.push(format el)

	if (m = el.tagName.match /ul/i)
		for el in $('h4', el)
			hList.push(format el)

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
