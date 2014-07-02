_ = require 'lodash'
kit = require './kit'

module.exports = {

	kit

	create: (opts) ->
		opts ?= {
			db: null
			proxy: null
			service: {}
			renderer: {}
		}

		nb = {
			kit
		}

		for k, v of opts
			if opts[k]
				nb[k] = require('./modules/' + k)(v)

		if nb.service and nb.service.io and nb.renderer
			nb.renderer.on 'file_modified', (path) ->
				nb.service.io.emit 'file_modified', path

		nb

	# return promise
	available_modules: ->
		kit.glob(__dirname + '/modules/*')
		.then (paths) ->
			list = {}
			paths.forEach (p) ->
				ext = kit.path.extname p
				name = kit.path.basename p, ext
				list[name] = (require './modules/' + name).defaults
			list
}
