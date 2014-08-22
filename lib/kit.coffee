colors = require 'colors'
colors.mode = 'none' if process.env.NODE_ENV == 'production'
_ = require 'lodash'
Q = require 'q'
fs = require 'fs-more'
glob = require 'glob'

###*
 * The `kit` lib of NoBone will load by default and is not optional.
 * All the async functions in `kit` return promise object.
 * Most time I use it to handle files and system staffs.
 * @type {Object}
###
kit = {}

###*
 * kit extends all the Q functions of [fs-more][fs-more].
 * [fs-more]: https://github.com/ysmood/fs-more
 * @example
 * ```coffeescript
 * kit.readFile('test.txt').done (str) ->
 * 	console.log str
 *
 * kit.outputFile('a.txt', 'test').done()
 * ```
###
kit_extends_fs_q = 'Q'
for k, v of fs
	if k.slice(-1) == 'Q'
		kit[k.slice(0, -1)] = fs[k]

_.extend kit, {

	###*
	 * The lodash lib.
	 * @type {Object}
	###
	_: _

	require_cache: {}

	###*
	 * An throttle version of `Q.all`, it runs all the tasks under
	 * a concurrent limitation.
	 * @param  {Int} limit The max task to run at the same time. It's optional.
	 * Default is Infinity.
	 * @param  {Array | Function} list
	 * If the list is an array, it should be a list of functions or promises. And each function will return a promise.
	 * If the list is a function, it should be a iterator that returns a promise,
	 * when it returns `undefined`, the iteration ends.
	 * @param {Boolean} save_resutls Whether to save each promise's result or not.
	 * @return {Promise} You can get each round's results by using the `promise.progress`.
	###
	async: (limit, list, save_resutls = true) ->
		from = 0
		resutls = []
		iter_index = 0
		is_iter_done = false
		defer = Q.defer()

		if not _.isNumber limit
			save_resutls = list
			list = limit
			limit = Infinity

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
			throw new Error('unknown list type: ' + typeof list)

		round = ->
			curr = []
			for i in [0 ... limit]
				p = iter(iter_index++)
				if is_iter_done or p == undefined
					is_iter_done = true
					break
				if Q.isPromise p
					p.then (ret) -> defer.notify ret
				else
					defer.notify p
				curr.push p

			if curr.length > 0
				Q.all curr
				.catch (err) ->
					defer.reject err
				.then (rets) ->
					if save_resutls
						resutls = resutls.concat rets
					round()
			else
				if save_resutls
					defer.resolve resutls
				else
					defer.resolve()

		round()

		defer.promise

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
				ejs = kit.require 'ejs'
				data.filename = path
				ejs.render str, data
		}

		kit.glob(opts.patterns, { cwd: opts.src_dir })
		.then (paths) ->
			Q.all paths.map (path) ->
				src_path = kit.path.join opts.src_dir, path
				dest_path = kit.path.join opts.dest_dir, path

				kit.readFile(src_path, 'utf8')
				.then (str) ->
					opts.compile str, opts.data, src_path
				.then (code) ->
					kit.outputFile dest_path, code
				.catch (err) ->
					if err.code != 'EISDIR'
						throw err

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
		Q.all patterns.map (p) ->
			kit._glob p, opts
			.then (paths) ->
				all_paths = _.union all_paths, paths
		.then ->
			all_paths

	_glob: Q.denodeify glob

	###*
	 * See my [jhash][jhash] project.
	 * [jhash]: https://github.com/ysmood/jhash
	###
	jhash: require 'jhash'

	###*
	 * It will find the right `key/value` pair in your defined `kit.lang_set`.
	 * If it cannot file the one, it will output the key directly.
	 * @param  {String} cmd  The original English text.
	 * @param  {String} lang The target language name.
	 * @param  {String} lang_set Specific a language collection.
	 * @return {String}
	 * @example
	 * Supports we have two json file in `langs_dir_path` folder.
	 * - cn.js, content: `module.exports = { China: '中国' }`
	 * - jp.coffee, content: `module.exports = 'Good weather.': '日和。'`
	 *
	 * ```coffeescript
	 * kit.lang_load 'langs_dir_path'
	 *
	 * kit.lang_current = 'cn'
	 * 'China'.l # '中国'
	 * 'Good weather.'.l('jp') # '日和。'
	 *
	 * kit.lang_current = 'en'
	 * 'China'.l # 'China'
	 * 'Good weather.'.l('jp') # 'Good weather.'
	 * ```
	###
	lang: (cmd, name = kit.lang_current, lang_set = kit.lang_set) ->
		i = cmd.lastIndexOf '|'
		en = if i > -1 then cmd[...i] else cmd
		lang_set[name]?[cmd] or en

	###*
	 * Language collections.
	 * @type {Object}
	 * @example
	 * ```coffeescript
	 * kit.lang_set = {
	 * 	'cn': { 'China': '中国' }
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
	 * Load language set directory and save them into
	 * the `kit.lang_set`.
	 * @param  {String} dir_path The directory path that contains
	 * js or coffee files.
	 * @example
	 * ```coffeescript
	 * kit.lang_load 'assets/lang'
	 * kit.lang_current = 'cn'
	 * kit.log 'test'.l # This may output '测试'.
	 * ```
	###
	lang_load: (dir_path) ->
		return if not _.isString dir_path
		dir_path = kit.fs.realpathSync dir_path

		paths = kit.fs.readdirSync dir_path
		for p in paths
			ext = kit.path.extname p
			continue if _.isEmpty ext
			name = kit.path.basename p, ext
			kit.lang_set[name] = require kit.path.join(dir_path, name)

		Object.defineProperty String.prototype, 'l', {
			get: (name, lang_set) -> kit.lang this, name, lang_set
		}

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
			colors: process.env.NODE_ENV == 'development'
			depth: 5
		}

		str = util.inspect obj, opts

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
				console.log '>> Log should match:'.yellow, process.env.log_reg
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

		if _.isObject msg
			log "[#{time}] ->\n" + kit.inspect(msg, opts), time_delta
		else
			log "[#{time}]", msg, time_delta

		if process.env.log_trace == 'on'
			log (new Error).stack.replace('Error:', '\nStack trace:').grey

		if action == 'error'
			console.log "\u0007\n"

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

		ps = null
		start = ->
			ps = kit.spawn(
				opts.bin
				opts.args
				kit.env_mode opts.mode
			).process

		start()

		process.on 'SIGINT', ->
			ps.kill 'SIGINT'

		kit.watch_files opts.watch_list, (path, curr, prev) ->
			if curr.mtime != prev.mtime
				kit.log "Reload app, modified: ".yellow + path +
					'\n' + _.times(64, ->'*').join('').yellow
				ps.kill 'SIGINT'
				start()

		kit.log "Monitor: ".yellow + opts.watch_list

		ps

	###*
	 * Open a thing that your system can recognize.
	 * Now only support Windows and OSX.
	 * @param  {String} cmd  The thing you want to open.
	 * @param  {Object} opts The options of the node native `child_process.exec`.
	 * @example
	 * ```coffeescript
	 * # Open a webpage with the default browser.
	 * kit.open 'http://ysmood.org'
	 * ```
	 * @return {Promise} When the child process exits.
	###
	open: (cmd, opts = {}) ->
		{ exec } = kit.require 'child_process'

		defer = Q.defer()

		switch process.platform
			when 'darwin'
				cmds = ['open']
			when 'win32'
				cmds = ['start']
			else
				cmds = []

		cmds.push cmd
		exec cmds.join(' '), opts, (err, stdout, stderr) ->
			if err
				defer.reject err
			else
				defer.resolve { stdout, stderr }

		defer.promise

	###*
	 * String padding helper.
	 * @example
	 * ```coffeescript
	 * kit.pad '1', 3 # '001'
	 * ```
	 * @param  {Sting | Number} str
	 * @param  {Number} width
	 * @param  {String} char Padding char. Default is '0'.
	 * @return {String}
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
						if opts.name_tags.indexOf(tag.tag_name) > -1
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

		defer = Q.defer()
		prompt.get opts, (err, res) ->
			if err
				defer.reject err
			else
				defer.resolve res

		defer.promise

	###*
	 * The promise Q lib.
	 * @type {Object}
	###
	q: Q

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

		url = kit.url.parse opts.url
		url.protocol ?= 'http:'

		request = null
		switch url.protocol
			when 'http:'
				{ request } = kit.require 'http'
			when 'https:'
				{ request } = kit.require 'https'
			else
				throw new Error('Protocol not supported: ' + url.protocol)

		_.defaults opts, url

		_.defaults opts, {
			body: true
			res_encoding: 'auto' # set null to use buffer
			req_data: null # string or buffer.
			auto_end_req: true
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

		defer = Q.defer()
		req = request opts, (res) ->
			if opts.redirect > 0 and res.headers.location
				opts.redirect--
				kit.request(
					_.extend opts, kit.url.parse(res.headers.location)
				)
				.catch (err) -> defer.reject err
				.done (val) -> defer.resolve val
				return

			if opts.res_pipe
				res_pipe_error = (err) ->
					defer.reject err
					opts.res_pipe.end()

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

				opts.res_pipe.on 'error', res_pipe_error
				res.on 'error', res_pipe_error
				res.on 'end', -> defer.resolve res
			else
				buf = new Buffer(0)
				res.on 'data', (chunk) ->
					buf = Buffer.concat [buf, chunk]

				res.on 'end', ->
					resolve = (body) ->
						if opts.body
							defer.resolve body
						else
							res.body = body
							defer.resolve res

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
								defer.reject err

						switch res.headers['content-encoding']
							when 'gzip'
								unzip = kit.require('zlib').gunzip
							when 'deflate'
								unzip = kit.require('zlib').inflate
							else
								unzip = null
						if unzip
							unzip buf, (err, buf) ->
								resolve decode(buf)
						else
							resolve decode(buf)
					else
						resolve buf

		req.on 'error', (err) ->
			# Release pipe
			opts.res_pipe?.end()
			defer.reject err

		if opts.req_pipe
			opts.req_pipe.pipe req
		else
			if opts.auto_end_req
				if req_buf.length > 0
					req.end req_buf
				else
					req.end()

		defer.promise.req = req
		defer.promise

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
			cmd_ext = cmd + '.cmd'
			if fs.existsSync cmd_ext
				cmd = cmd_ext
			else
				which = kit.require 'which'
				cmd = which.sync(cmd)
			cmd = kit.path.normalize cmd

		defer = Q.defer()

		{ spawn } = kit.require 'child_process'

		try
			ps = spawn cmd, args, opts
		catch err
			defer.reject err

		ps.on 'error', (err) ->
			defer.reject err

		ps.on 'exit', (worker, code, signal) ->
			defer.resolve { worker, code, signal }

		defer.promise.process = ps

		return defer.promise

	###*
	 * Node native module
	###
	url: require 'url'

	###*
	 * Watch a file. If the file changes, the handler will be invoked.
	 * You can change the polling interval by using `process.env.polling_watch`
	 * For samba server, we have to choose `watchFile` than `watch`.
	 * variable.
	 * @param  {String}   path    The file path
	 * @param  {Function} handler Event listener.
	 * The handler has these params:
	 * - file path
	 * - current `fs.Stats`
	 * - previous `fs.Stats`
	 * - if its a deletion
	 * @example
	 * ```coffeescript
	 * kit.watch_file 'a.js', (path, curr, prev) ->
	 * 	if curr.mtime != prev.mtime
	 * 		kit.log path
	 * ```
	 * @param {Boolean} auto_unwatch Auto unwatch the file while file deletion.
	 * Default is true.
	 * @return {Function} The real listener.
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
				persistent: false
				interval: +process.env.polling_watch or 300
			}
			listener
		)
		listener

	###*
	 * Watch files, when file changes, the handler will be invoked.
	 * It takes the advantage of `kit.watch_file`.
	 * @param  {Array} patterns String array with minimatch syntax.
	 * Such as `['\*.css', 'lib/\*\*.js']`.
	 * @param  {Function} handler
	###
	watch_files: (patterns, handler) ->
		kit.glob(patterns).then (paths) ->
			paths.forEach (path) ->
				kit.watch_file path, handler
			paths

	###*
	 * Watch directory and all the files in it.
	 * It supports three types of change: create, modify, delete.
	 * @param  {Object} opts Defaults:
	 * {
	 * 	dir: '.'
	 * 	pattern: '**'
	 *
	 * 	# Whether to watch POSIX hidden file.
	 * 	dot: false
	 *
	 * 	# If the "path" ends with '/' it's a directory, else a file.
	 * 	handler: (type, path, curr, prev) ->
	 * }
	 * @example
	 * ```coffeescript
	 * # Only current folder, and only watch js and css file.
	 * kit.watch_dir {
	 * 	dir: 'lib'
	 * 	pattern: '*.+(js|css)'
	 * 	handler: (type, path) ->
	 * 		kit.log type
	 * 		kit.log path
	 * 	watched_list: [] # If you use watch_dir recursively, you need a global watched_list
	 * }
	 * ```
	 * @return {Promise}
	###
	watch_dir: (opts) ->
		_.defaults opts, {
			dir: '.'
			pattern: '**'
			dot: false
			handler: (type, path, curr, prev) ->
			watched_list: []
		}

		file_watcher = (path, curr, prev, is_delete) ->
			if is_delete
				opts.handler 'delete', path, curr, prev
				kit._.remove opts.watched_list, (el) -> el == path
			else
				opts.handler 'modify', path, curr, prev

		dir_watcher = (path, curr, prev, is_delete) ->
			if is_delete
				opts.handler 'delete', path, curr, prev
				kit._.remove opts.watched_list, (el) -> el == path
				return

			kit.glob(kit.path.join(path, opts.pattern), {
				mark: true, dot: opts.dot
			}).then (paths) ->
				for p in paths
					if opts.watched_list.indexOf(p) == -1
						if p[-1..] == '/'
							kit.watch_dir _.defaults({
								dir: p
								watched_list: opts.watched_list
							}, opts)
						else
							kit.watch_file p, file_watcher
							opts.watched_list.push p

						opts.handler 'create', p, curr, prev

		kit.glob(kit.path.join(opts.dir, opts.pattern), {
			mark: true, dot: opts.dot
		}).then (paths) ->
			for path in paths
				if path[-1..] == '/'
					kit.watch_file path, dir_watcher
				else
					kit.watch_file path, file_watcher
				opts.watched_list.push path
			opts.watched_list

}

# Fix node bugs
kit.path.delimiter = if process.platform == 'win32' then ';' else ':'

module.exports = kit