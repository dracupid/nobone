colors = require 'colors'
_ = require 'lodash'
Promise = require 'bluebird'
fs = require 'fs-more'

###*
 * All the async functions in `kit` return promise object.
 * Most time I use it to handle files and system staffs.
 * @type {Object}
###
kit = {}

###*
 * kit extends all the promise functions of [fs-more][fs-more].
 * [fs-more]: https://github.com/ysmood/fs-more
 * @example
 * ```coffeescript
 * kit.readFile('test.txt').done (str) ->
 * 	console.log str
 *
 * kit.outputFile('a.txt', 'test').done()
 * ```
###
kit_extends_fs_promise = 'promise'
for k, v of fs
	if k.slice(-1) == 'P'
		kit[k.slice(0, -1)] = fs[k]

_.extend kit, {

	###*
	 * The lodash lib.
	 * @type {Object}
	###
	_: _

	require_cache: {}

	###*
	 * An throttle version of `Promise.all`, it runs all the tasks under
	 * a concurrent limitation.
	 * @param  {Int} limit The max task to run at the same time. It's optional.
	 * Default is Infinity.
	 * @param  {Array | Function} list
	 * If the list is an array, it should be a list of functions or promises, and each function will return a promise.
	 * If the list is a function, it should be a iterator that returns a promise,
	 * when it returns `undefined`, the iteration ends.
	 * @param {Boolean} save_resutls Whether to save each promise's result or not. Default is true.
	 * @param {Function} progress If a task ends, the resolve value will be passed to this function.
	 * @return {Promise}
	 * @example
	 * ```coffeescript
	 * urls = [
	 * 	'http://a.com'
	 * 	'http://b.com'
	 * 	'http://c.com'
	 * 	'http://d.com'
	 * ]
	 * tasks = [
	 * 	-> kit.request url[0]
	 * 	-> kit.request url[1]
	 * 	-> kit.request url[2]
	 * 	-> kit.request url[3]
	 * ]
	 *
	 * kit.async(tasks).then ->
	 * 	kit.log 'all done!'
	 *
	 * kit.async(2, tasks).then ->
	 * 	kit.log 'max concurrent limit is 2'
	 *
	 * kit.async 3, ->
	 * 	url = urls.pop()
	 * 	if url
	 * 		kit.request url
	 * .then ->
	 * 	kit.log 'all done!'
	 * ```
	###
	async: (limit, list, save_resutls, progress) ->
		from = 0
		resutls = []
		iter_index = 0
		running = 0
		is_iter_done = false

		if not _.isNumber limit
			progress = save_resutls
			save_resutls = list
			list = limit
			limit = Infinity

		save_resutls ?= true

		if _.isArray list
			list_len = list.length - 1
			iter = (i) ->
				return if i > list_len
				if _.isFunction list[i]
					list[i](i)
				else
					list[i]

		else if _.isFunction list
			iter = list
		else
			Promise.reject new Error('unknown list type: ' + typeof list)

		new Promise (resolve, reject) ->
			add_task = ->
				task = iter(iter_index++)
				if is_iter_done or task == undefined
					is_iter_done = true
					all_done() if running == 0
					return false

				if _.isFunction(task.then)
					p = task
				else
					p = Promise.resolve task

				running++
				p.then (ret) ->
					running--
					if save_resutls
						resutls.push ret
					progress? ret
					add_task()
				.catch (err) ->
					running--
					reject err

				return true

			all_done = ->
				if save_resutls
					resolve resutls
				else
					resolve()

			for i in [0 ... limit]
				break if not add_task()

	###*
	 * Creates a function that is the composition of the provided functions.
	 * Besides it can also accept async function that returns promise.
	 * It's more powerful than `_.compose`.
	 * @param  {Function | Array} fns Functions that return promise or any value.
	 * And the array can also contains promises.
	 * @return {Function} A composed function that will return a promise.
	 * @example
	 * ```coffeescript
	 * # It helps to decouple sequential pipeline code logic.
	 *
	 * create_url = (name) ->
	 * 	return "http://test.com/" + name
	 *
	 * curl = (url) ->
	 * 	kit.request(url).then ->
	 * 		kit.log 'get'
	 *
	 * save = (str) ->
	 * 	kit.outputFile('a.txt', str).then ->
	 * 		kit.log 'saved'
	 *
	 * download = kit.compose create_url, curl, save
	 * # same as "download = kit.compose [create_url, curl, save]"
	 *
	 * download 'home'
	 * ```
	###
	compose: (fns...) -> (val) ->
		fns = fns[0] if _.isArray fns[0]

		fns.reduce (pre_fn, fn) ->
			if _.isFunction fn.then
				pre_fn.then -> fn
			else
				pre_fn.then fn
		, Promise.resolve(val)

	###*
	 * Daemonize a program.
	 * @param  {Object} opts Defaults:
	 * {
	 * 	bin: 'node'
	 * 	args: ['app.js']
	 * 	stdout: 'stdout.log'
	 * 	stderr: 'stderr.log'
	 * }
	 * @return {Porcess} The daemonized process.
	###
	daemonize: (opts = {}) ->
		_.defaults opts, {
			bin: 'node'
			args: ['app.js']
			stdout: 'stdout.log'
			stderr: 'stderr.log'
		}

		out_log = os.openSync(opts.stdout, 'a')
		err_log = os.openSync(opts.stderr, 'a')

		p = kit.spawn(opts.bin, opts.args, {
			detached: true
			stdio: [ 'ignore', out_log, err_log ]
		}).process
		p.unref()
		kit.log "Run as background daemon, PID: #{p.pid}".yellow
		p

	###*
	 * A simple decrypt helper
	 * @param  {Any} data
	 * @param  {String | Buffer} password
	 * @param  {String} algorithm Default is 'aes128'.
	 * @return {Buffer}
	###
	decrypt: (data, password, algorithm = 'aes128') ->
		crypto = kit.require 'crypto'
		decipher = crypto.createDecipher algorithm, password

		if kit.node_version() < 0.10
			if Buffer.isBuffer data
				data = data.toString 'binary'
			new Buffer(
				decipher.update(data, 'binary') + decipher.final()
				'binary'
			)
		else
			if not Buffer.isBuffer data
				data = new Buffer(data)
			Buffer.concat [decipher.update(data), decipher.final()]

	###*
	 * A simple encrypt helper
	 * @param  {Any} data
	 * @param  {String | Buffer} password
	 * @param  {String} algorithm Default is 'aes128'.
	 * @return {Buffer}
	###
	encrypt: (data, password, algorithm = 'aes128') ->
		crypto = kit.require 'crypto'
		cipher = crypto.createCipher algorithm, password

		if kit.node_version() < 0.10
			if Buffer.isBuffer data
				data = data.toString 'binary'
			new Buffer(
				cipher.update(data, 'binary') + cipher.final()
				'binary'
			)
		else
			if not Buffer.isBuffer data
				data = new Buffer(data)
			Buffer.concat [cipher.update(data), cipher.final()]

	###*
	 * A shortcut to set process option with specific mode,
	 * and keep the current env variables.
	 * @param  {String} mode 'development', 'production', etc.
	 * @return {Object} `process.env` object.
	###
	env_mode: (mode) ->
		{
			env: _.defaults(
				{ NODE_ENV: mode }
				process.env
			)
		}

	###*
	 * A log error shortcut for `kit.log(msg, 'error', opts)`
	 * @param  {Any} msg
	 * @param  {Object} opts
	###
	err: (msg, opts = {}) ->
		kit.log msg, 'error', opts

	###*
	 * A better `child_process.exec`.
	 * @param  {String} cmd   Shell commands.
	 * @param  {String} shell Shell name. Such as `bash`, `zsh`. Optinal.
	 * @return {Promise} Resolves when the process's stdio is drained.
	 * @example
	 * ```coffeescript
	 * kit.exec """
	 * a=10
	 * echo $a
	 * """
	 *
	 * # Bash doesn't support "**" recusive match pattern.
	 * kit.exec """
	 * echo **\/*.css
	 * """, 'zsh'
	 * ```
	###
	exec: (cmd, shell) ->
		stream = kit.require 'stream'

		shell = process.env.SHELL or
			process.env.ComSpec or
			process.env.COMSPEC

		cmd_stream = new stream.Transform
		cmd_stream.push cmd
		cmd_stream.end()

		stdout = ''
		out_stream = new stream.Writable
		out_stream._write = (chunk) ->
			stdout += chunk

		stderr = ''
		err_stream = new stream.Writable
		err_stream._write = (chunk) ->
			stderr += chunk

		p = kit.spawn shell, [], {
			stdio: 'pipe'
		}
		cmd_stream.pipe p.process.stdin
		p.process.stdout.pipe out_stream
		p.process.stderr.pipe err_stream

		p.then (msg) ->
			_.extend msg, { stdout, stderr }

	###*
	 * See my project [fs-more][fs-more].
	 * [fs-more]: https://github.com/ysmood/fs-more
	###
	fs: fs

	###*
	 * A scaffolding helper to generate template project.
	 * The `lib/cli.coffee` used it as an example.
	 * @param  {Object} opts Defaults:
	 * ```coffeescript
	 * {
	 * 	src_dir: null
	 * 	patterns: '**'
	 * 	dest_dir: null
	 * 	data: {}
	 * 	compile: (str, data, path) ->
	 * 		compile str
	 * }
	 * ```
	 * @return {Promise}
	###
	generate_bone: (opts) ->
		###
			It will treat all the files in the path as an ejs file
		###
		_.defaults opts, {
			src_dir: null
			patterns: ['**', '**/.*']
			dest_dir: null
			data: {}
			compile: (str, data, path) ->
				data.filename = path
				_.template str, data
		}

		kit.glob(opts.patterns, { cwd: opts.src_dir })
		.then (paths) ->
			Promise.all paths.map (path) ->
				src_path = kit.path.join opts.src_dir, path
				dest_path = kit.path.join opts.dest_dir, path

				kit.readFile(src_path, 'utf8')
				.then (str) ->
					opts.compile str, opts.data, src_path
				.then (code) ->
					kit.outputFile dest_path, code
				.catch (err) ->
					if err.cause.code != 'EISDIR'
						Promise.reject err

	###*
	 * See the https://github.com/isaacs/node-glob
	 * @param {String | Array} patterns Minimatch pattern.
	 * @param {Object} opts The glob options.
	 * @return {Promise} Contains the path list.
	###
	glob: (patterns, opts) ->
		if _.isString patterns
			patterns = [patterns]

		all_paths = []
		stat_cache = {}
		Promise.all patterns.map (p) ->
			kit._glob p, opts
			.then (paths) ->
				_.extend stat_cache, paths.glob.statCache
				all_paths = _.union all_paths, paths
		.then ->
			all_paths.stat_cache = stat_cache
			all_paths

	_glob: (pattern, opts) ->
		glob = kit.require 'glob'
		new Promise (resolve, reject) ->
			g = glob pattern, opts, (err, paths) ->
				paths.glob = g
				if err
					reject err
				else
					resolve paths

	###*
	 * See my [jhash][jhash] project.
	 * [jhash]: https://github.com/ysmood/jhash
	###
	jhash: require 'jhash'

	###*
	 * It will find the right `key/value` pair in your defined `kit.lang_set`.
	 * If it cannot find the one, it will output the key directly.
	 * @param  {String} cmd The original text.
	 * @param  {String} name The target language name.
	 * @param  {String} lang_set Specific a language collection.
	 * @return {String}
	 * @example
	 * ```coffeescript
	 * lang_set =
	 * 	human:
	 * 		cn: '人类'
	 * 		jp: '人間'
	 *
	 * 	open:
	 * 		cn:
	 * 			formal: '开启' # Formal way to say 'open'.
	 * 			casual: '打开' # Casual way to say 'open'.
	 *
	 * 	'find %s men': '%sっ人が見付かる'
	 *
	 * kit.lang('human', 'cn', lang_set) # -> '人类'
	 * kit.lang('open|casual', 'cn', lang_set) # -> '打开'
	 * kit.lang('find %s men', [10], 'jp', lang_set) # -> '10っ人が見付かる'
	 * ```
	 * @example
	 * ```coffeescript
	 * kit.lang_load 'lang.coffee'
	 *
	 * kit.lang_current = 'cn'
	 * 'human'.l # '人类'
	 * 'Good weather.'.lang('jp') # '日和。'
	 *
	 * kit.lang_current = 'en'
	 * 'human'.l # 'human'
	 * 'Good weather.'.lang('jp') # 'Good weather.'
	 * ```
	###
	lang: (cmd, args = [], name, lang_set) ->
		if _.isString args
			lang_set = name
			name = args
			args = []

		name ?= kit.lang_current
		lang_set ?= kit.lang_set

		i = cmd.lastIndexOf '|'
		if i > -1
			key = cmd[...i]
			cat = cmd[i + 1 ..]
		else
			key = cmd

		set = lang_set[key]

		out = if _.isObject set
			if set[name] == undefined
				key
			else
				if cat == undefined
					set[name]
				else if _.isObject set[name]
					set[name][cat]
				else
					key
		else if _.isString set
		 	set
		else
			key

		if args.length > 0
			util = kit.require 'util'
			args.unshift out
			util.format.apply util, args
		else
			out

	###*
	 * Language collections.
	 * @type {Object}
	 * @example
	 * ```coffeescript
	 * kit.lang_set = {
	 * 	'cn': { 'human': '人类' }
	 * }
	 * ```
	###
	lang_set: {}

	###*
	 * Current default language.
	 * @type {String}
	 * @default 'en'
	###
	lang_current: 'en'

	###*
	 * Load language set and save them into the `kit.lang_set`.
	 * Besides, it will also add properties `l` and `lang` to `String.prototype`.
	 * @param  {String} file_path
	 * js or coffee files.
	 * @example
	 * ```coffeescript
	 * kit.lang_load 'assets/lang'
	 * kit.lang_current = 'cn'
	 * kit.log 'test'.l # -> '测试'.
	 * kit.log '%s persons'.lang([10]) # -> '10 persons'
	 * ```
	###
	lang_load: (lang_path) ->
		return if not _.isString lang_path
		lang_path = kit.path.resolve lang_path
		kit.lang_set = require lang_path

		Object.defineProperty String.prototype, 'l', {
			get: -> kit.lang this + ''
		}

		String.prototype.lang = (args...) ->
			args.unshift this + ''
			kit.lang.apply null, args

	###*
	 * For debugging use. Dump a colorful object.
	 * @param  {Object} obj Your target object.
	 * @param  {Object} opts Options. Default:
	 * { colors: true, depth: 5 }
	 * @return {String}
	###
	inspect: (obj, opts) ->
		util = kit.require 'util'

		_.defaults opts, {
			colors: kit.is_development()
			depth: 5
		}

		str = util.inspect obj, opts

	###*
	 * Nobone use it to check the running mode of the app.
	 * Overwrite it if you want to control the check logic.
	 * By default it returns the `rocess.env.NODE_ENV == 'development'`.
	 * @return {Boolean}
	###
	is_development: ->
		process.env.NODE_ENV == 'development'

	###*
	 * Nobone use it to check the running mode of the app.
	 * Overwrite it if you want to control the check logic.
	 * By default it returns the `rocess.env.NODE_ENV == 'production'`.
	 * @return {Boolean}
	###
	is_production: ->
		process.env.NODE_ENV == 'production'

	###*
	 * A better log for debugging, it uses the `kit.inspect` to log.
	 *
	 * You can use terminal command like `log_reg='pattern' node app.js` to
	 * filter the log info.
	 *
	 * You can use `log_trace='on' node app.js` to force each log end with a
	 * stack trace.
	 * @param  {Any} msg Your log message.
	 * @param  {String} action 'log', 'error', 'warn'.
	 * @param  {Object} opts Default is same with `kit.inspect`
	###
	log: (msg, action = 'log', opts = {}) ->
		if not kit.last_log_time
			kit.last_log_time = new Date
			if process.env.log_reg
				kit.log_reg = new RegExp(process.env.log_reg)

		time = new Date()
		time_delta = (+time - +kit.last_log_time).toString().magenta + 'ms'
		kit.last_log_time = time
		time = [
			[
				kit.pad time.getFullYear(), 4
				kit.pad time.getMonth() + 1, 2
				kit.pad time.getDate(), 2
			].join('-')
			[
				kit.pad time.getHours(), 2
				kit.pad time.getMinutes(), 2
				kit.pad time.getSeconds(), 2
			].join(':')
		].join(' ').grey

		log = ->
			str = _.toArray(arguments).join ' '

			if kit.log_reg and not kit.log_reg.test(str)
				return

			console[action] str.replace /\n/g, '\n  '

			if process.env.log_trace == 'on'
				console.log (new Error).stack.replace(/.+\n.+\n.+/, '\nStack trace:').grey

		if _.isObject msg
			log "[#{time}] ->\n" + kit.inspect(msg, opts), time_delta
		else
			log "[#{time}]", msg, time_delta

		if action == 'error'
			process.stdout.write "\u0007"

	###*
	 * Monitor an application and automatically restart it when file changed.
	 * When the monitored app exit with error, the monitor itself will also exit.
	 * It will make sure your app crash properly.
	 * @param  {Object} opts Defaults:
	 * ```coffeescript
	 * {
	 * 	bin: 'node'
	 * 	args: ['app.js']
	 * 	watch_list: ['app.js']
	 * 	mode: 'development'
	 * }
	 * ```
	 * @return {Process} The child process.
	###
	monitor_app: (opts) ->
		_.defaults opts, {
			bin: 'node'
			args: ['app.js']
			watch_list: ['app.js']
			mode: 'development'
		}

		sep_line = ->
			console.log _.times(process.stdout.columns, -> '*').join('').yellow

		child_ps = null
		start = ->
			sep_line()

			child_ps = kit.spawn(
				opts.bin
				opts.args
				kit.env_mode opts.mode
			).process

			child_ps.on 'close', (code, sig) ->
				child_ps.is_closed = true

				kit.log 'EXIT'.yellow + " code: #{(code + '').cyan} signal: #{(sig + '').cyan}"

				if code != null and code != 0
					kit.log 'Process closed. Edit and save the watched file to restart.'.red

		process.on 'SIGINT', ->
			child_ps.kill 'SIGINT'
			process.exit()

		kit.watch_files opts.watch_list, (path, curr, prev) ->
			if curr.mtime != prev.mtime
				kit.log "Reload app, modified: ".yellow + path

				if child_ps.is_closed
					start()
				else
					child_ps.on 'close', start
					child_ps.kill 'SIGINT'

		kit.log "Monitor: ".yellow + opts.watch_list

		start()

		child_ps

	###*
	 * Node version. Such as `v0.10.23` is `0.1023`, `v0.10.1` is `0.1001`.
	 * @type {Float}
	###
	node_version: ->
		ms = process.versions.node.match /(\d+)\.(\d+)\.(\d+)/
		str = ms[1] + '.' + kit.pad(ms[2], 2) + kit.pad(ms[3], 2)
		+str

	###*
	 * Open a thing that your system can recognize.
	 * Now only support Windows, OSX or system that installed 'xdg-open'.
	 * @param  {String} cmd  The thing you want to open.
	 * @param  {Object} opts The options of the node native `child_process.exec`.
	 * @return {Promise} When the child process exits.
	 * @example
	 * ```coffeescript
	 * # Open a webpage with the default browser.
	 * kit.open 'http://ysmood.org'
	 * ```
	###
	open: (cmd, opts = {}) ->
		{ exec } = kit.require 'child_process'

		switch process.platform
			when 'darwin'
				cmds = ['open']
			when 'win32'
				cmds = ['start']
			else
				which = kit.require 'which'
				try
					cmds = [which.sync('xdg-open')]
				catch
					cmds = []

		cmds.push cmd

		new Promise (resolve, reject) ->
			exec cmds.join(' '), opts, (err, stdout, stderr) ->
				if err
					reject err
				else
					resolve { stdout, stderr }

	###*
	 * String padding helper.
	 * @param  {Sting | Number} str
	 * @param  {Number} width
	 * @param  {String} char Padding char. Default is '0'.
	 * @return {String}
	 * @example
	 * ```coffeescript
	 * kit.pad '1', 3 # '001'
	 * ```
	###
	pad: (str, width, char = '0') ->
		str = str + ''
		if str.length >= width
			str
		else
			new Array(width - str.length + 1).join(char) + str

	###*
	 * A comments parser for coffee-script. Used to generate documentation automatically.
	 * It will traverse through all the comments.
	 * @param  {String} module_name The name of the module it belongs to.
	 * @param  {String} code Coffee source code.
	 * @param  {String} path The path of the source code.
	 * @param  {Object} opts Parser options:
	 * ```coffeescript
	 * {
	 * 	comment_reg: RegExp
	 * 	split_reg: RegExp
	 * 	tag_name_reg: RegExp
	 * 	type_reg: RegExp
	 * 	name_reg: RegExp
	 * 	name_tags: ['param', 'property']
	 * 	description_reg: RegExp
	 * }
	 * ```
	 * @return {Array} The parsed comments. Each item is something like:
	 * ```coffeescript
	 * {
	 * 	module: 'nobone'
	 * 	name: 'parse_comment'
	 * 	description: 'A comments parser for coffee-script.'
	 * 	tags: [
	 * 		{
	 * 			tag_name: 'param'
	 * 			type: 'string'
	 * 			name: 'code'
	 * 			description: 'The name of the module it belongs to.'
	 * 			path: 'http://the_path_of_source_code'
	 * 			index: 256 # The target char index in the file.
	 * 			line: 32 # The line number of the target in the file.
	 * 		}
	 * 	]
	 * }
	 * ```
	###
	parse_comment: (module_name, code, path = '', opts = {}) ->
		_.defaults opts, {
			comment_reg: /###\*([\s\S]+?)###\s+([\w\.]+)/g
			split_reg: /^\s+\* @/m
			tag_name_reg: /^([\w\.]+)\s*/
			type_reg: /^\{(.+?)\}\s*/
			name_reg: /^(\w+)\s*/
			name_tags: ['param', 'property']
			description_reg: /^([\s\S]*)/
		}

		parse_info = (block) ->
			# Unescape '\/'
			block = block.replace /\\\//g, '/'

			# Clean the prefix '*'
			arr = block.split(opts.split_reg).map (el) ->
				el.replace(/^[ \t]+\*[ \t]?/mg, '').trim()

			{
				description: arr[0] or ''
				tags: arr[1..].map (el) ->
					parse_tag = (reg) ->
						m = el.match reg
						if m and m[1]
							el = el[m[0].length..]
							m[1]
						else
							null

					tag = {}

					tag.tag_name = parse_tag opts.tag_name_reg

					type = parse_tag opts.type_reg
					if type
						tag.type = type
						if tag.tag_name in opts.name_tags
							tag.name = parse_tag opts.name_reg
						tag.description = parse_tag(opts.description_reg) or ''
					else
						tag.description = parse_tag(opts.description_reg) or ''
					tag
			}

		comments = []
		m = null
		while (m = opts.comment_reg.exec(code)) != null
			info = parse_info m[1]
			comments.push {
				module: module_name
				name: m[2]
				description: info.description
				tags: info.tags
				path
				index: opts.comment_reg.lastIndex
				line: _.reduce(code[...opts.comment_reg.lastIndex]
				, (count, char) ->
					count++ if char == '\n'
					count
				, 1)
			}

		return comments

	###*
	 * Node native module
	###
	path: require 'path'

	###*
	 * Block terminal and wait for user inputs. Useful when you need
	 * in-terminal user interaction.
	 * @param  {Object} opts See the https://github.com/flatiron/prompt
	 * @return {Promise} Contains the results of prompt.
	###
	prompt_get: (opts) ->
		prompt = kit.require 'prompt', (prompt) ->
			prompt.message = '>> '
			prompt.delimiter = ''

		new Promise (resolve, reject) ->
			prompt.get opts, (err, res) ->
				if err
					reject err
				else
					resolve res

	###*
	 * The promise lib.
	 * @type {Object}
	###
	Promise: Promise

	###*
	 * Much much faster than the native require of node, but
	 * you should follow some rules to use it safely.
	 * @param  {String}   module_name Moudle path is not allowed!
	 * @param  {Function} done Run only the first time after the module loaded.
	 * @return {Module} The module that you require.
	###
	require: (module_name, done) ->
		if not kit.require_cache[module_name]
			if module_name[0] == '.'
				throw new Error('Only module name is allowed: ' + module_name)

			kit.require_cache[module_name] = require module_name
			done? kit.require_cache[module_name]

		kit.require_cache[module_name]

	###*
	 * A powerful extended combination of `http.request` and `https.request`.
	 * @param  {Object} opts The same as the [http.request][http.request], but with
	 * some extra options:
	 * ```coffeescript
	 * {
	 * 	url: 'It is not optional, String or Url Object.'
	 * 	body: true # Other than return `res` with `res.body`, return `body` directly.
	 * 	redirect: 0 # Max times of auto redirect. If 0, no auto redirect.
	 *
	 * 	# Set null to use buffer, optional.
	 * 	# It supports GBK, Shift_JIS etc.
	 * 	# For more info, see https://github.com/ashtuchkin/iconv-lite
	 * 	res_encoding: 'auto'
	 *
	 * 	# It's string, object or buffer, optional. When it's an object,
	 * 	# The request will be 'application/x-www-form-urlencoded'.
	 * 	req_data: null
	 *
	 * 	auto_end_req: true # auto end the request.
	 * 	req_pipe: Readable Stream.
	 * 	res_pipe: Writable Stream.
	 * }
	 * ```
	 * And if set opts as string, it will be treated as the url.
	 * [http.request]: http://nodejs.org/api/http.html#http_http_request_options_callback
	 * @return {Promise} Contains the http response object,
	 * it has an extra `body` property.
	 * You can also get the request object by using `Promise.req`, for example:
	 * ```coffeescript
	 * p = kit.request 'http://test.com'
	 * p.req.on 'response', (res) ->
	 * 	kit.log res.headers['content-length']
	 * p.done (body) ->
	 * 	kit.log body # html or buffer
	 *
	 * kit.request {
	 * 	url: 'https://test.com'
	 * 	body: false
	 * }
	 * .done (res) ->
	 * 	kit.log res.body
	 * 	kit.log res.headers
	 * ```
	###
	request: (opts) ->
		if _.isString opts
			opts = { url: opts }

		if _.isObject opts.url
			opts.url.protocol ?= 'http:'
			opts.url = kit.url.format opts.url
		else
			if opts.url.indexOf('http') != 0
				opts.url = 'http://' + opts.url

		url = kit.url.parse opts.url
		url.protocol ?= 'http:'

		request = null
		switch url.protocol
			when 'http:'
				{ request } = kit.require 'http'
			when 'https:'
				{ request } = kit.require 'https'
			else
				Promise.reject new Error('Protocol not supported: ' + url.protocol)

		_.defaults opts, url

		_.defaults opts, {
			body: true
			res_encoding: 'auto'
			req_data: null
			auto_end_req: true
			auto_unzip: true
		}

		opts.headers ?= {}
		if Buffer.isBuffer(opts.req_data)
			req_buf = opts.req_data
		else if _.isString opts.req_data
			req_buf = new Buffer(opts.req_data)
		else if _.isObject opts.req_data
			opts.headers['content-type'] ?= 'application/x-www-form-urlencoded; charset=utf-8'
			req_buf = new Buffer(
				_.map opts.req_data, (v, k) ->
					[encodeURIComponent(k), encodeURIComponent(v)].join '='
				.join '&'
			)
		else
			req_buf = new Buffer(0)

		if req_buf.length > 0
			opts.headers['content-length'] ?= req_buf.length

		req = null
		promise = new Promise (resolve, reject) ->
			req = request opts, (res) ->
				if opts.redirect > 0 and res.headers.location
					opts.redirect--
					kit.request(
						_.extend opts, kit.url.parse(res.headers.location)
					)
					.catch (err) -> reject err
					.done (val) -> resolve val
					return

				if opts.res_pipe
					res_pipe_error = (err) ->
						reject err
						opts.res_pipe.end()

					if opts.auto_unzip
						switch res.headers['content-encoding']
							when 'gzip'
								unzip = kit.require('zlib').createGunzip()
							when 'deflate'
								unzip = kit.require('zlib').createInflat()
							else
								unzip = null
						if unzip
							unzip.on 'error', res_pipe_error
							res.pipe(unzip).pipe(opts.res_pipe)
						else
							res.pipe opts.res_pipe
					else
						res.pipe opts.res_pipe

					opts.res_pipe.on 'error', res_pipe_error
					res.on 'error', res_pipe_error
					res.on 'end', -> resolve res
				else
					buf = new Buffer(0)
					res.on 'data', (chunk) ->
						buf = Buffer.concat [buf, chunk]

					res.on 'end', ->
						resolver = (body) ->
							if opts.body
								resolve body
							else
								res.body = body
								resolve res

						if opts.res_encoding
							encoding = 'utf8'
							if opts.res_encoding == 'auto'
								c_type = res.headers['content-type']
								if _.isString c_type
									m = c_type.match(/charset=(.+);?/i)
									if m and m[1]
										encoding = m[1]
									if not /^(text)|(application)\//.test(c_type)
										encoding = null

							decode = (buf) ->
								if not encoding
									return buf
								try
									if encoding == 'utf8'
										buf.toString()
									else
										kit.require('iconv-lite')
										.decode buf, encoding
								catch err
									reject err

							if opts.auto_unzip
								switch res.headers['content-encoding']
									when 'gzip'
										unzip = kit.require('zlib').gunzip
									when 'deflate'
										unzip = kit.require('zlib').inflate
									else
										unzip = null
								if unzip
									unzip buf, (err, buf) ->
										resolver decode(buf)
								else
									resolver decode(buf)
							else
								resolver decode(buf)
						else
							resolver buf

			req.on 'error', (err) ->
				# Release pipe
				opts.res_pipe?.end()
				reject err

			if opts.req_pipe
				opts.req_pipe.pipe req
			else
				if opts.auto_end_req
					if req_buf.length > 0
						req.end req_buf
					else
						req.end()

		promise.req = req
		promise

	###*
	 * A safer version of `child_process.spawn` to run a process on Windows or Linux.
	 * It will automatically add `node_modules/.bin` to the `PATH` environment variable.
	 * @param  {String} cmd Path of an executable program.
	 * @param  {Array} args CLI arguments.
	 * @param  {Object} opts Process options. Same with the Node.js official doc.
	 * Default will inherit the parent's stdio.
	 * @return {Promise} The `promise.process` is the child process object.
	 * When the child process ends, it will resolve.
	###
	spawn: (cmd, args = [], opts = {}) ->
		PATH = process.env.PATH or process.env.Path
		[
			kit.path.normalize __dirname + '/../node_modules/.bin'
			kit.path.normalize process.cwd() + '/node_modules/.bin'
		].forEach (path) ->
			if PATH.indexOf(path) < 0 and kit.fs.existsSync(path)
				PATH = [path, PATH].join kit.path.delimiter
		process.env.PATH = PATH
		process.env.Path = PATH

		_.defaults opts, {
			stdio: 'inherit'
		}

		if process.platform == 'win32'
			which = kit.require 'which'
			cmd = which.sync cmd
			if cmd.slice(-3).toLowerCase() == 'cmd'
				cmd_src = kit.fs.readFileSync(cmd, 'utf8')
				m = cmd_src.match(/node\s+"%~dp0\\(\.\.\\.+)"/)
				if m and m[1]
					cmd = kit.path.join cmd, '..', m[1]
					cmd = kit.path.normalize cmd
					args = [cmd].concat args
					cmd = 'node'

		{ spawn } = kit.require 'child_process'

		ps = null
		promise = new Promise (resolve, reject) ->
			try
				ps = spawn cmd, args, opts
			catch err
				reject err

			ps.on 'error', (err) ->
				reject err

			ps.on 'close', (code, signal) ->
				resolve { code, signal }

		promise.process = ps
		promise

	###*
	 * Node native module
	###
	url: require 'url'

	###*
	 * Watch a file. If the file changes, the handler will be invoked.
	 * You can change the polling interval by using `process.env.polling_watch`.
	 * Use `process.env.watch_persistent = 'off'` to disable the persistent.
	 * For samba server, we have to choose `watchFile` other than `watch`.
	 * @param  {String}   path    The file path
	 * @param  {Function} handler Event listener.
	 * The handler has these params:
	 * - file path
	 * - current `fs.Stats`
	 * - previous `fs.Stats`
	 * - if its a deletion
	 * @param {Boolean} auto_unwatch Auto unwatch the file while file deletion.
	 * Default is true.
	 * @return {Function} The wrapped watch listeners.
	 * @example
	 * ```coffeescript
	 * process.env.watch_persistent = 'off'
	 * kit.watch_file 'a.js', (path, curr, prev, is_deletion) ->
	 * 	if curr.mtime != prev.mtime
	 * 		kit.log path
	 * ```
	###
	watch_file: (path, handler, auto_unwatch = true) ->
		listener = (curr, prev) ->
			is_deletion = curr.mtime.getTime() == 0
			handler(path, curr, prev, is_deletion)
			if is_deletion
				kit.fs.unwatchFile path, listener

		fs.watchFile(
			path
			{
				persistent: process.env.watch_persistent != 'off'
				interval: +process.env.polling_watch or 300
			}
			listener
		)
		listener

	###*
	 * Watch files, when file changes, the handler will be invoked.
	 * It takes the advantage of `kit.watch_file`.
	 * @param  {Array} patterns String array with minimatch syntax.
	 * Such as `['*\/**.css', 'lib\/**\/*.js']`.
	 * @param  {Function} handler
	 * @return {Promise} It contains the wrapped watch listeners.
	 * @example
	 * ```coffeescript
	 * kit.watch_files '*.js', (path, curr, prev, is_deletion) ->
	 * 	kit.log path
	 * ```
	###
	watch_files: (patterns, handler) ->
		kit.glob(patterns).then (paths) ->
			paths.map (path) ->
				kit.watch_file path, handler

	###*
	 * Watch directory and all the files in it.
	 * It supports three types of change: create, modify, move, delete.
	 * @param  {Object} opts Defaults:
	 * ```coffeescript
	 * {
	 * 	dir: '.'
	 * 	pattern: '**' # minimatch, string or array
	 *
	 * 	# Whether to watch POSIX hidden file.
	 * 	dot: false
	 *
	 * 	# If the "path" ends with '/' it's a directory, else a file.
	 * 	handler: (type, path, old_path) ->
	 * }
	 * ```
	 * @return {Promise}
	 * @example
	 * ```coffeescript
	 * # Only current folder, and only watch js and css file.
	 * kit.watch_dir {
	 * 	dir: 'lib'
	 * 	pattern: '*.+(js|css)'
	 * 	handler: (type, path) ->
	 * 		kit.log type
	 * 		kit.log path
	 * 	watched_list: {} # If you use watch_dir recursively, you need a global watched_list
	 * }
	 * ```
	###
	watch_dir: (opts) ->
		_.defaults opts, {
			dir: '.'
			pattern: '**'
			dot: false
			handler: (type, path, old_path) ->
			watched_list: {}
			deleted_list: {}
		}

		if _.isString opts.pattern
			opts.pattern = [opts.pattern]

		expand_watch_pattern = (root, pattern) ->
			# Make sure the parent directory is also in the watch list.
			parent_dirs = []
			patterns = pattern.map (el) ->
				p = kit.path.join(root, el)
				parent_dirs.push kit.path.dirname(p) + kit.path.sep
				p
			_.union patterns, parent_dirs

		is_same_file = (stats_a, stats_b) ->
			stats_a.mtime.getTime() == stats_b.mtime.getTime() and
			stats_a.ctime.getTime() == stats_b.ctime.getTime() and
			stats_a.size == stats_b.size

		recursive_watch = (path) ->
			if path[-1..] == '/'
				# Recursively watch a newly created directory.
				kit.watch_dir _.defaults({
					dir: path
				}, opts)
			else
				opts.watched_list[path] = kit.watch_file path, file_watcher

		file_watcher = (path, curr, prev, is_delete) ->
			if is_delete
				opts.deleted_list[path] = prev
			else
				opts.handler 'modify', path

		main_watch = (path, curr, prev, is_delete) ->
			if is_delete
				opts.deleted_list[path] = prev
				return

			# Each time a direcotry change happens, it will check all
			# it children files, if any child is not in the watched_list,
			# a `create` event will be triggered.
			kit.glob(
				expand_watch_pattern path, opts.pattern
				{
					mark: true
					dot: opts.dot
					nosort: true
				}
			).then (paths) ->
				for p in paths.sort().reverse()
					if opts.watched_list[p] != undefined
						continue

					# Check if the new file is renamed from another file.
					if not _.any(opts.deleted_list, (stat, dpath) ->
						if stat == 'parent_moved'
							delete opts.deleted_list[dpath]
							return true

						if is_same_file(stat, paths.stat_cache[p])
							# All children will be deleted, so that
							# sub-move event won't trigger.
							for k of opts.deleted_list
								if k.indexOf(dpath) == 0
									opts.deleted_list[k] = 'parent_moved'
									delete opts.watched_list[k]
							delete opts.deleted_list[dpath]
							recursive_watch p
							opts.handler 'move', p, dpath
							true
						else
							false
					)
						recursive_watch p
						opts.handler 'create', p

				_.each opts.watched_list, (v, wpath) ->
					if wpath not in paths and
					wpath.indexOf(path) == 0
						delete opts.deleted_list[wpath]
						delete opts.watched_list[wpath]
						opts.handler 'delete', wpath

			.catch (err) ->
				kit.err err

		kit.glob(
			expand_watch_pattern opts.dir, opts.pattern
			{
				mark: true
				dot: opts.dot
				nosort: true
			}
		).then (paths) ->
			# The reverse will keep the children event happen at first.
			for path in paths.sort().reverse()
				if path[-1..] == '/'
					w = kit.watch_file path, main_watch
				else
					w = kit.watch_file path, file_watcher
				opts.watched_list[path] = w
			opts.watched_list

}

# Fix node bugs
kit.path.delimiter = if process.platform == 'win32' then ';' else ':'

# Some debug options.
if kit.is_development()
	Promise.longStackTraces()
else
	colors.mode = 'none'

module.exports = kit