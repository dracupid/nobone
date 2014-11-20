###*
 * NoBone has several modules and a helper lib.
 * **All the modules are optional**.
 * Only the `kit` lib is loaded by default and is not optional.
 *
 * Most of the async functions are implemented with [Promise][Promise].
 * [Promise]: https://github.com/petkaantonov/bluebird
###
Overview = 'nobone'

_ = require 'lodash'
kit = require './kit'
{ Promise } = kit

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
 * 	lang: null
 *
 * 	lang_path: null # language set directory
 * }
 * ```
 * @return {Object} A nobone instance.
###
nobone = (modules) ->
	modules ?= {
		service: {}
		renderer: {}
		db: null
		proxy: null
		lang: null
	}

	nb = {
		kit
	}

	for k, v of modules
		if modules[k]
			mod = require './modules/' + k
			nobone[k] = mod
			nb[k] = mod v

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
		Promise.all _.map(modules, (v, k) ->
			mod = nb[k]
			if v and mod.close
				if mod.close.length > 0
					Promise.promisify(mod.close, mod)()
				else
					Promise.resolve mod.close()
		)
	nb.close = close

	nb

_.extend nobone, {

	kit

	###*
	 * Get current nobone version string.
	 * @return {String}
	###
	version: ->
		require('../package').version

	###*
	 * Check if nobone need to be upgraded.
	 * @return {Promise}
	###
	check_upgrade: ->
		kit.request 'https://registry.npmjs.org/nobone/latest'
		.done (data) ->
			{ version: ver } = JSON.parse data
			if ver > nobone.version()
				info = "nobone@#{ver}".yellow
				console.warn "[ A new version of ".green + info + " is available. ]".green

	###*
	 * The NoBone client helper.
	 * @static
	 * @param {Object} opts The options of the client, defaults:
	 * ```coffeescript
	 * {
	 * 	auto_reload: kit.is_development()
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
			auto_reload: kit.is_development()
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

if kit.is_development()
	nobone.check_upgrade()

module.exports = nobone
