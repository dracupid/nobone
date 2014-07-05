_ = require 'lodash'
kit = require './kit'
Q = require 'q'


###*
 * Main constructor.
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	db: null
 * 	proxy: null
 * 	service: {}
 * 	renderer: {}
 * }```
 * @return {Object} A nobone instance.
###
nobone = (opts) ->
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

	###*
	 * Release the resources.
	 * @return {Promise}
	###
	nb.close = ->
		Q.all _.map(opts, (v, k) ->
			mod = nb[k]
			if v and mod.close
				if mod.close.length > 0
					Q.ninvoke mod, 'close'
				else
					mod.close()
		)

	nb

_.extend nobone, {

	kit

	###*
	 * Help you to get the default options of moduels.
	 * @param {String} name Module name, if not set, return all modules' defaults.
	 * @return {Promise} A promise object which will produce the defaults.
	###
	module_defaults: (name) ->
		kit.glob(__dirname + '/modules/*')
		.then (paths) ->
			list = []
			paths.forEach (p) ->
				ext = kit.path.extname p
				mod = kit.path.basename p, ext
				list[mod] = (require './modules/' + mod).defaults

			if name
				list[name]
			else
				list
}

module.exports = nobone
