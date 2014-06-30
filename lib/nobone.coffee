_ = require 'lodash'

module.exports = nb = {

	init: (opts) ->
		opts ?= {
			db: null
			proxy: null
			service: {}
			renderer: {}
		}

		for k, v of opts
			if opts[k]
				nb[k] = require('./modules/' + k)(v)

		nb

	available_modules: ->
		nb.kit.glob(__dirname + '/modules/*')
		.then (paths) ->
			list = {}
			paths.forEach (p) ->
				ext = nb.kit.path.extname p
				name = nb.kit.path.basename p, ext
				list[name] = (require './modules/' + name).defaults
			list

	_: _
	kit: require './kit'

}
