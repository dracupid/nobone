###*
 * NoBone has several modules and a helper lib.
 * **All the modules are optional**.
 *
 * Most of the async functions are inplemented with [Q][Q].
 * [Q]: https://github.com/kriskowal/q
###
Overview = 'nobone'

_ = require 'lodash'
kit = require './kit'
Q = require 'q'


###*
 * Main constructor.
 * @param  {Object} modules By default, it only load two modules,
 * `service` and `renderer`:
 * ```coffeescript
 * {
 * 	service: {}
 * 	renderer: {}
 * 	db: null
 * 	proxy: null
 *
 * 	lang_dir: null # language set directory
 * }
 * ```
 * @param {Object} opts Other options.
 * @return {Object} A nobone instance.
###
nobone = (modules, opts = {}) ->
	modules ?= {
		db: null
		proxy: null
		service: {}
		renderer: {}
	}

	_.defaults opts, {
		lang_dir: null
	}

	nb = {
		kit
	}

	for k, v of modules
		if modules[k]
			nb[k] = require('./modules/' + k)(v)

	if nb.service and nb.service.sse and nb.renderer
		nb.renderer.on 'file_modified', (path, ext_bin, req_path) ->
			nb.service.sse.emit(
				'file_modified'
				{ path, ext_bin, req_path }
				'/auto_reload'
			)

	# Load language.
	kit.lang_load opts.lang_dir

	###*
	 * Release the resources.
	 * @return {Promise}
	###
	close = ->
		Q.all _.map(modules, (v, k) ->
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
	 * The NoBone client helper.
	 * @static
	 * @param {Object} opts The options of the client, defaults:
	 * ```coffeescript
	 * {
	 * 	auto_reload: process.env.NODE_ENV == 'development'
	 * 	lang_current: kit.lang_current
	 * 	lang_data: kit.lang_data
	 * 	host: '' # The host of the event source.
	 * }
	 * ```
	 * @param {Boolean} use_js By default use html. Default is false.
	 * @return {String} The code of client helper.
	###
	client: (opts = {}, use_js = false) ->
		if nobone.client_js_cache
			js = nobone.client_js_cache
		else
			js = kit.fs.readFileSync(__dirname + '/../dist/nobone_client.js')
			nobone.client_js_cache = js

		opts_str = JSON.stringify _.defaults(opts, {
			auto_reload: process.env.NODE_ENV == 'development'
			lang_current: kit.lang_current
			lang_data: kit.lang_data
			host: ''
		})

		js = """
			\n#{js}
			window.nb = new Nobone(#{opts_str});\n
		"""

		if use_js
			js
		else
			"""
				\n\n<!-- Nobone Client Helper -->
				<script type="text/javascript">
				#{js}
				</script>\n\n
			"""

}

module.exports = nobone
