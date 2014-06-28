
module.exports = nb = {

	init: (opts) ->
		opts ?= {
			service: undefined
			renderer: undefined
		}

		for k, v of opts
			nb[k] = require('./' + k)(v)

	kit: require './kit'

}
