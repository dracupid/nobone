
$ = (qs, self = document) ->
	self.querySelectorAll qs

create_div = (str) ->
	div = document.createElement 'div'
	div.innerHTML = str
	div

space = (n) ->
	[0...n]
	.map -> '<b class="space">·</b>'
	.join ''

format = (h) ->
	tag = h.tagName
	n = +tag.match(/\d+/) - min_h
	div = create_div """
		#{space(n)}
		<#{tag}>
			#{h.textContent.trim()}
		</#{tag}>
	"""

	$(tag, div)[0].addEventListener 'click', ->
		h.scrollIntoView()

	div

find_pos = (obj) ->
	curtop = 0
	if obj.offsetParent
		while obj = obj.offsetParent
			curtop += obj.offsetTop
		curtop += obj.offsetTop
	return curtop

h_list = []

all_h = $('h1, h2, h3, h4, h5, h6', $('#main')[0])
min_h = [].slice.apply(all_h).reduce((m, el) ->
	n = +el.tagName.match(/h(\d)/i)[1]
	if m < n then m else n
, 100)

for el in all_h
	if (m = el.tagName.match /h\d+/i)
		h_list.push(format el)

	if (m = el.tagName.match /ul/i)
		for el in $('h4', el)
			h_list.push(format el)

toc = $('#toc')[0]
content = $('.content', toc)[0]

h_list.forEach (el) -> content.appendChild el

document.body.appendChild toc

# If toc title clicked, toggle the visibility of toc.
toc_title = $('#toc > h1')[0]

if localStorage.getItem('toc') == 'hide'
	toc.style.height = '60px'

toc_title.addEventListener 'click', ->
	if toc.style.height == '60px'
		toc.style.height = null
		localStorage.setItem 'toc', 'show'
	else
		localStorage.setItem 'toc', 'hide'
		toc.style.height = '60px'
