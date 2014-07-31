###*
 * NoBone has several modules and a helper lib.
 * **All the modules are optional**.
 *
 * Most of the async functions are inplemented with [Q][0].
 * [0]: https://github.com/kriskowal/q
###
Overview = 'nobone'

_ = require 'lodash'
kit = require './kit'
Q = require 'q'


###*
 * Main constructor.
 * @param  {Object} opts By default, it only load two modules,
 * `service` and `renderer`:
 * ```coffee
 * {
 * 	service: {}
 * 	renderer: {}
 * 	db: null
 * 	proxy: null
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

	if nb.service and nb.service.sse and nb.renderer
		nb.renderer.on 'file_modified', (path, ext_bin, req_path) ->
			nb.service.sse.emit(
				'file_modified'
				{ path, ext_bin, req_path }
				'/auto_reload'
			)

	###*
	 * Release the resources.
	 * @return {Promise}
	###
	close = ->
		Q.all _.map(opts, (v, k) ->
			mod = nb[k]
			if v and mod.close
				if mod.close.length > 0
					Q.ninvoke mod, 'close'
				else
					mod.close()
		)
	nb.close = close

	nb

_.extend nobone, {

	kit

	###*
	 * Help you to get the default options of moduels.
	 * @static
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

	###*
	 * The NoBone client helper.
	 * @static
	 * @param {Object} opts The options of the client, defaults:
	 * ```coffee
	 * {
	 * 	auto_reload: process.env.NODE_ENV == 'development'
	 * 	lang_current: kit.lang_current
	 * 	lang_data: kit.lang_data
	 * }
	 * ```
	 * return an empty string.
	 * @return {String} The html of client helper.
	###
	client: (opts = {}) ->
		if nobone.client_cache
			return nobone.client_cache

		fs = kit.require 'fs'
		js = fs.readFileSync(__dirname + '/../dist/nobone_client.js')
		opts_str = JSON.stringify _.defaults(opts, {
			auto_reload: process.env.NODE_ENV == 'development'
			lang_current: kit.lang_current
			lang_data: kit.lang_data
		})
		html = """
			\n\n<!-- Nobone Client Helper -->
			<script type="text/javascript">
			#{js}
			window.nb = new Nobone(#{opts_str});
			</script>\n\n
		"""
		nobone.client_cache = html

}

module.exports = nobone
