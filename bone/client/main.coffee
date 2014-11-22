class <%- className %> then constructor: ->
	self = @

	init = ->
		document.querySelector 'h1'
		.classList.add '<%- name %>'

	init()

<%- name %> = new <%- className %>
