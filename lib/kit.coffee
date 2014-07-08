require 'colors'
_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
glob = require 'glob'

###*
 * The `kit` lib of NoBone will load by default and is not optional.
 * All the async functions in `kit` return promise object.
 * Most time I use it to handle files and system staffs.
 * @type {Object}
###
kit = {}

###*
 * Create promise wrap for all the functions that has
 * Sync version. For more info see node official doc of `fs`
 * There are some extra `fs` functions here,
 * see: https://github.com/jprichardson/node-fs-extra
 * You can call `fs.readFile` like `kit.readFile`, it will
 * return a promise object.
 * @example
 * ```coffee
 * kit.readFile('a.coffee').done (code) ->
 * 	kit.log code
 * ```
###
denodeify_fs = ->
	_.chain(fs)
	.functions()
	.filter (el) ->
		el.slice(-4) == 'Sync'
	.each (name) ->
		name = name.slice(0, -4)
		kit[name] = Q.denodeify fs[name]

denodeify_fs()

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
	 * See my jhash project: https://github.com/ysmood/jhash
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
	 * @param  {String} cmd Path of an executable program.
	 * @param  {Array} args CLI arguments.
	 * @param  {Object} opts Process options. Same with the Node.js official doc.
	 * Default will inherit the parent's stdio.
	 * @return {Promise} The `promise.process` is the child process object.
	###
	spawn: (cmd, args = [], opts = {}) ->
		_.defaults opts, { stdio: 'inherit' }

		if process.platform == 'win32'
			cmd_ext = cmd + '.cmd'
			if fs.existsSync cmd_ext
				cmd = cmd_ext
			else
				which = kit.require 'which'
				cmd = which.sync(cmd)
			cmd = kit.path.normalize cmd

		deferred = Q.defer()

		{ spawn } = kit.require 'child_process'
		try
			ps = spawn cmd, args, opts
		catch err
			deferred.reject err

		ps.on 'error', (err) ->
			deferred.reject err

		ps.on 'exit', (worker, code, signal) ->
			deferred.resolve worker, code, signal

		deferred.promise.process = ps

		return deferred.promise

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

	exists: (path) ->
		deferred = Q.defer()
		fs.exists path, (exists) ->
			deferred.resolve exists
		return deferred.promise

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
		time = time.toJSON().slice(0, -5).replace('T', ' ').grey

		if kit.log_reg and not msg.match(kit.log_reg)
			return

		log = ->
			str = _.toArray(arguments).join ' '
			console[action] str.replace /\n/g, '\n  '

		if typeof msg != 'string'
			log "[#{time}] ->\n" + kit.inspect(msg, opts), time_delta
		else
			log "[#{time}]", msg, time_delta

		if process.env.log_trace == 'on'
			log (new Error).stack.replace('Error:', '\nStack trace:').grey

		if action == 'error'
			console.log "\u0007\n"

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

		deferred = Q.defer()
		prompt.get opts, (err, res) ->
			if err
				deferred.reject err
			else
				deferred.resolve res

		deferred.promise

	###*
	 * An throttle version of `Q.all`, it runs all the tasks under
	 * a concurrent limitation.
	 * @param  {Array} list A list of functions. Each will return a promise.
	 * @param  {Int} limit The max task to run at the same time.
	 * @return {Promise}
	###
	async_limit: (list, limit) ->
		from = 0
		resutls = []

		round = ->
			to = from + limit
			curr = list[from ... to].map (el) -> el()
			from = to
			if curr.length > 0
				Q.all curr
				.then (res) ->
					resutls = resutls.concat res
					round()
			else
				Q(resutls)

		round()

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

	###*
	 * Check if a file path exists.
	 * @param  {String}  path
	 * @return {Boolean}
	###
	is_file_exists: (path) ->
		kit.exists path
		.then (exists) ->
			if exists
				kit.stat(path)
				.then (stats) ->
					stats.isFile()
			else
				false

	###*
	 * Check if a directory path exists.
	 * @param  {String}  path
	 * @return {Boolean}
	###
	is_dir_exists: (path) ->
		kit.exists path
		.then (exists) ->
			if exists
				kit.stat(path)
				.then (stats) ->
					stats.isDirectory()
			else
				false

}

module.exports = kit