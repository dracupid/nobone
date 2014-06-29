
module.exports = nb = {

	init: (opts) ->
		opts ?= {
			service: undefined
			renderer: undefined
		}

		for k, v of opts
			nb[k] = require('./modules/' + k)(v)

	available_modules: ->
		nb.kit.glob(__dirname + '/modules/*')
		.then (paths) ->
			list = {}
			paths.forEach (p) ->
				ext = nb.kit.path.extname p
				name = nb.kit.path.basename p, ext
				list[name] = (require './modules/' + name).defaults
			list

	kit: require './kit'

}
