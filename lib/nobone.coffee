###*
 * NoBone has several modules and a helper lib.
 * **All the modules are optional**.
 * Only the `kit` lib is loaded by default and is not optional.
 *
 * Most of the async functions are implemented with [Promise][Promise].
 * [Promise]: https://github.com/petkaantonov/bluebird
###
Overview = 'nobone'

kit = require './kit'
{ _, Promise } = kit

###*
 * Main constructor.
 * @param  {Object} modules By default, it only load two modules,
 * `service` and `renderer`:
 * ```coffee
 * {
 * 	service: {}
 * 	renderer: {}
 * 	db: null
 * 	proxy: null
 * 	lang: null
 *
 * 	langPath: null # language set directory
 * }
 * ```
 * @param {Object} opts Defaults:
 * ```coffee
 * {
 * 	# Whether to auto-check the version of nobone.
 * 	checkUpgrade: true
 *
 *	# Whether to enable the sse live reload.
 * 	autoReload: true
 * }
 * ```
 * @return {Object} A nobone instance.
###
nobone = (modules, opts = {}) ->
	modules ?= {
		service: {}
		renderer: {}
		db: null
		proxy: null
		lang: null
	}

	_.defaults opts, {
		checkUpgrade: true
		autoReload: true
	}

	nb = {
		kit
	}

	for k, v of modules
		if modules[k]
			# Let monitor work: require './modules/*.coffee'
			mod = require './modules/' + k
			nobone[k] = mod
			nb[k] = mod v

	if opts.autoReload and nb.renderer
		nb.renderer.on 'fileModified', (path, extBin, reqPath) ->
			nb.service?.sse?.emit(
				'fileModified'
				{ path, extBin, reqPath }
				'/autoReload'
			)

	if opts.checkUpgrade
		nobone.checkUpgrade().catch(->)

	###*
	 * Release the resources.
	 * @return {Promise}
	###
	close = ->
		Promise.all _.map(modules, (v, k) ->
			mod = nb[k]
			if v and mod.close
				if mod.close.length > 0
					kit.promisify(mod.close, mod)()
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
	checkUpgrade: ->
		kit.request 'https://registry.npmjs.org/nobone/latest'
		.then (data) ->
			{ version: ver } = JSON.parse data
			curr_ver = nobone.version()
			if ver > curr_ver
				path = kit.path.normalize kit.path.join(__dirname, '..')
				info = "nobone@#{ver}".green
				console.warn "[ A new version of ".grey +
					info + " is available. ".grey +
					"Current is v#{curr_ver} (#{path})]".grey

	###*
	 * The NoBone client helper.
	 * @static
	 * @param {Object} opts The options of the client, defaults:
	 * ```coffee
	 * {
	 * 	autoReload: kit.isDevelopment()
	 * 	host: '' # The host of the event source.
	 * }
	 * ```
	 * @param {Boolean} useJs By default use html. Default is false.
	 * @return {String} The code of client helper.
	###
	client: (opts = {}, useJs = false) ->
		if nobone.clientJsCache
			js = nobone.clientJsCache
		else
			js = kit.fs.readFileSync(__dirname + '/../dist/noboneClient.js')
			nobone.clientJsCache = js

		optsStr = JSON.stringify _.defaults(opts, {
			autoReload: kit.isDevelopment()
			host: ''
		})

		js = """
			\n#{js}
			window.nb = new Nobone(#{optsStr});\n
		"""

		if useJs
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
