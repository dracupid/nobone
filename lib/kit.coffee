require 'colors'
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
 * kit extends all the Q functions of [fs-more][0].
 * [0]: https://github.com/ysmood/fs-more
 * @example
 * ```coffee
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

	require_cache: {}

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
	 * Node native module
	###
	path: require 'path'

	###*
	 * Node native module
	###
	url: require 'url'

	###*
	 * See my project [fs-more](https://github.com/ysmood/fs-more)
	###
	fs: fs

	###*
	 * See my [jhash][0] project.
	 * [0]: https://github.com/ysmood/jhash
	###
	jhash: require 'jhash'

	###*
	 * See the https://github.com/isaacs/node-glob
	 * @param {String | Array} patterns Minimatch pattern.
	 * @return {Promise} Contains the path list.
	###
	glob: (patterns, opts) ->
		if _.isString patterns
			patterns = [patterns]

		Q.all patterns.map (p) ->
			kit._glob p, opts
		.then (rets) ->
			_.flatten rets

	_glob: Q.denodeify glob

	###*
	 * Safe version of `child_process.spawn` to run a process on Windows or Linux.
	 * It will automatically add `node_modules/.bin` to the `PATH` environment variable.
	 * @param  {String} cmd Path of an executable program.
	 * @param  {Array} args CLI arguments.
	 * @param  {Object} opts Process options. Same with the Node.js official doc.
	 * Default will inherit the parent's stdio.
	 * @return {Promise} The `promise.process` is the child process object.
	###
	spawn: (cmd, args = [], opts = {}) ->
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

		kit.extend_env()

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
	 * Open a thing that your system can recognize.
	 * Now only support Windows and OSX.
	 * @param  {String} cmd  The thing you want to open.
	 * @param  {Object} opts The options of the node native `child_process.exec`.
	 * @return {Promise}
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
	 * A simple wrapper for `http.request`
	 * @param  {Object} opts The same as the [http.request][0], but with
	 * some extra options:
	 * ```coffee
	 * {
	 * 	url: 'It is not optional.'
	 * 	res_encoding: 'utf8' # set null to use buffer, optional.
	 * 	req_data: null # string or buffer, optional.
	 * 	req_pipe: Readable Stream.
	 * 	res_pipe: Writable Stream.
	 * }
	 * ```
	 * And if set opts as string, it will be treated as the url.
	 * [0]: http://nodejs.org/api/http.html#http_http_request_options_callback
	 * @return {Promise} Contains the http response data.
	###
	request: (opts) ->
		if _.isString opts
			opts = { url: opts }

		url = kit.url.parse opts.url

		if not url.protocol
			url = kit.url.parse 'http://' + opts.url

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
			res_encoding: 'utf8' # set null to use buffer
			req_data: null # string or buffer.
		}

		defer = Q.defer()
		req = request opts, (res) ->
			if opts.res_pipe
				res.pipe opts.res_pipe
				res.on 'end', -> defer.resolve()
			else
				buf = new Buffer(0)
				res.on 'data', (chunk) ->
					buf = Buffer.concat [buf, chunk]

				res.on 'end', ->
					if opts.res_encoding
						data = buf.toString opts.res_encoding
					else
						data = buf
					defer.resolve data

		req.on 'error', (err) ->
			# Release pipe
			opts.res_pipe?.end()
			defer.reject err

		if opts.req_pipe
			opts.req_pipe.pipe req
		else
			req.end opts.req_data

		defer.promise

	###*
	 * Automatically add `node_modules/.bin` to the `PATH` environment variable.
	###
	extend_env: ->
		PATH = process.env.PATH
		[
			kit.path.normalize __dirname + '/../node_modules/.bin'
			kit.path.normalize process.cwd + '/node_modules/.bin'
		].forEach (path) ->
			if PATH.indexOf path < 0
				PATH = [path, PATH].join kit.path.delimiter
		process.env.PATH = PATH

	###*
	 * Monitor an application and automatically restart it when file changed.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	bin: 'node'
	 * 	args: ['app.js']
	 * 	watch_list: ['app.js']
	 * 	mode: 'development'
	 * }```
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

	watch_file: (path, handler) ->
		###
			For samba server, we have to choose `watchFile` than `watch`
		###

		fs.watchFile(
			path
			{
				persistent: false
				interval: +process.env.polling_watch or 500
			}
			(curr, prev) ->
				handler(path, curr, prev)
		)

	###*
	 * Watch files, when file changes, the handler will be invoked.
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
	 * For debugging use. Dump a colorful object.
	 * @param  {Object} obj Your target object.
	 * @param  {Object} opts Options. Default:
	 * { colors: true, depth: 5 }
	 * @return {String}
	###
	inspect: (obj, opts) ->
		util = kit.require 'util'

		_.defaults opts, { colors: true, depth: 5 }

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

		if kit.log_reg and not msg.match(kit.log_reg)
			return

		log = ->
			str = _.toArray(arguments).join ' '
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
	 * String padding helper.
	 * @param  {Sting | Number} str
	 * @param  {Number} width
	 * @param  {String} char Padding char. Default is '0'.
	 * @return {[type]}       [description]
	###
	pad: (str, width, char = '0') ->
		str = str + ''
		if str.length >= width
			str
		else
			new Array(width - str.length + 1).join(char) + str

	###*
	 * A log error shortcut for `kit.log`
	 * @param  {Any} msg
	 * @param  {Object} opts
	###
	err: (msg, opts = {}) ->
		kit.log msg, 'error', opts

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
	 * Block terminal and wait for user inputs. Useful when you need
	 * user interaction.
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
	 * An throttle version of `Q.all`, it runs all the tasks under
	 * a concurrent limitation.
	 * @param  {Int} limit The max task to run at the same time. It's optional.
	 * Default is Infinity.
	 * @param  {Array | Function} list A list of functions. Each will return a promise.
	 * If it is a function, it should be a iterator that returns a promise,
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
				list[i](i)
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
	 * A comments parser for coffee-script. Used to generate documentation automatically.
	 * It will traverse through all the comments.
	 * @param  {String} module_name The name of the module it belongs to.
	 * @param  {String} code Coffee source code.
	 * @param  {String} path The path of the source code.
	 * @param  {Object} opts Parser options:
	 * ```coffee
	 * {
	 * 	comment_reg: RegExp
	 * 	split_reg: RegExp
	 * 	tag_name_reg: RegExp
	 * 	type_reg: RegExp
	 * 	name_reg: RegExp
	 * 	description_reg: RegExp
	 * }```
	 * @return {Array} The parsed comments. Each item is something like:
	 * ```coffee
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
	 * }```
	###
	parse_comment: (module_name, code, path = '', opts = {}) ->
		_.defaults opts, {
			comment_reg: /###\*([\s\S]+?)###\s+([\w\.]+)/g
			split_reg: /^\s+\* @/m
			tag_name_reg: /^([\w\.]+)\s*/
			type_reg: /^\{(.+?)\}\s*/
			name_reg: /^(\w+)\s*/
			description_reg: /^([\s\S]*)/
		}

		marked = kit.require 'marked'

		parse_info = (block) ->
			# Clean the prefix '*'
			arr = block.split(opts.split_reg).map (el) ->
				el.replace(/^[ \t]+\*[ \t]?/mg, '').trim()

			{
				description: marked(arr[0] or '')
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
						if tag.tag_name == 'param'
							tag.name = parse_tag opts.name_reg
						tag.description = marked(
							parse_tag(opts.description_reg) or ''
						)
					else
						tag.description = marked(
							parse_tag(opts.description_reg) or ''
						)

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
	 * A scaffolding helper to generate template project.
	 * The `lib/cli.coffee` used it as an example.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	prompt: null
	 * 	src_dir: null
	 * 	pattern: '**'
	 * 	dest_dir: null
	 * 	compile: (str, data, path) ->
	 * 		compile str
	 * }```
	 * @return {Promise}
	###
	generate_bone: (opts) ->
		###
			It will treat all the files in the path as an ejs file
		###
		_.defaults opts, {
			prompt: null
			src_dir: null
			pattern: '**'
			dest_dir: null
			compile: (str, data, path) ->
				ejs = kit.require 'ejs'
				data.filename = path
				ejs.render str, data
		}

		kit.prompt_get(opts.prompt)
		.then (data) ->
			kit.glob(opts.pattern, { cwd: opts.src_dir })
			.then (paths) ->
				Q.all paths.map (path) ->
					src_path = kit.path.join opts.src_dir, path
					dest_path = kit.path.join opts.dest_dir, path

					kit.readFile(src_path, 'utf8')
					.then (str) ->
						opts.compile str, data, src_path
					.then (code) ->
						kit.outputFile dest_path, code
					.catch (err) ->
						if err.code != 'EISDIR'
							throw err

}

module.exports = kit