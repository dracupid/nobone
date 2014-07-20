process.env.NODE_ENV = 'development'

assert = require 'assert'
http = require 'http'
Q = require 'q'
nobone = require '../lib/nobone'

nb = nobone {
	db: {}
	renderer: {}
	service: {}
}

describe 'Basic:', ->


	it 'the renderer with data should work', (tdone) ->
		nb.renderer.render(
			'bone/index.ejs'
			{ body: 'ok', name: 'nobone' }
		).done (page) ->
			nb.kit.log page
			# assert.equal page, '<!DOCTYPE html>\n<html>\n<head>\n\t<title>nobone</title>\n\t<link rel="stylesheet" type="text/css" href="/default.css">\n</head>\n<body>\n\n<%- nobone %>\n<script type="text/javascript" src="/main.js"></script>\n\n</body>\n</html>\n'
			tdone()
