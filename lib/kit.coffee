require 'colors'
_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
glob = require 'glob'

###*
 * The `kit` lib of NoBone will load by default and is not optinal.
 * All the async functions in `kit` return promise object.
 * Most time I use it to handle files and system staffs.
 * @type {object}
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
 * kit.readFile('a.coffee').done (code) ->
 * 	kit.log code
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

	_require_cache: {}

	_require: (path, done) ->
		###
			For better performance.
		###

		if not kit._require_cache[path]
			kit._require_cache[path] = require path
			done? kit._require_cache[path]

		kit._require_cache[path]

	###*
	 * Node native module
	###
	path: require 'path'

	###*
	 * Node native module
	###
	url: require 'url'

	###*
	 * See the https://github.com/isaacs/node-glob
	 * @param {string} pattern Minimatch pattern.
	 * @return {promise}
	###
	glob: Q.denodeify glob

	###*
	 * Safe version of `child_process.spawn` a process on Windows or Linux.
	 * @param  {string} cmd Path of an executable program.
	 * @param  {array} args CLI arguments.
	 * @param  {object} options Process options.
	 * Default will inherit the parent's stdio.
	 * @return {promise} The `promise.process` is the child process object.
	###
	spawn: (cmd, args = [], options = {}) ->
		if process.platform == 'win32'
			cmd_ext = cmd + '.cmd'
			if fs.existsSync cmd_ext
				cmd = cmd_ext
			else
				which = kit._require 'which'
				cmd = which.sync(cmd)
			cmd = kit.path.normalize cmd

		deferred = Q.defer()

		opts = _.defaults options, { stdio: 'inherit' }

		{ spawn } = kit._require 'child_process'
		try
			ps = spawn cmd, args, opts
		catch err
			deferred.reject err

		ps.on 'error', (err) ->
			deferred.reject err

		deferred.promise.process = ps

		return deferred.promise

	###*
	 * Monitor an application and automatically restart it when file changed.
	 * @param  {object} options Defaults:
	 * {
	 *     bin: 'node'
	 *     args: ['app.js']
	 *     watch_list: ['app.js']
	 *     mode: 'development'
	 * }
	 * @return {process} The child process.
	###
	monitor_app: (options) ->
		opts = _.defaults options, {
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
	 * @param  {array} patterns String array with minimatch syntax.
	 * Such as ['./* /**.js', '*.css']
	 * @param  {function} handler
	###
	watch_files: (patterns, handler) ->
		patterns.forEach (pattern) ->
			kit.glob(pattern).then (paths) ->
				paths.forEach (path) ->
					kit.watch_file path, handler

	###*
	 * A shortcut to set process option with specific mode,
	 * and keep the current env varialbes.
	 * @param  {string} mode 'development', 'production', etc.
	 * @return {object} `process.env` object.
	###
	env_mode: (mode) ->
		{
			env: _.extend(
				process.env, { NODE_ENV: mode }
			)
		}

	###*
	 * For debugging use. Dump a colorful object.
	 * @param  {object} obj Your target object.
	 * @param  {object} opts Options. Default:
	 * { colors: true, depth: 5 }
	 * @return {string}
	###
	inspect: (obj, opts) ->
		util = kit._require 'util'

		_.defaults opts, { colors: true, depth: 5 }

		str = util.inspect obj, opts

	###*
	 * A better log for debugging, it uses the `kit.inspect` to log.
	 * @param  {any} msg Your log message.
	 * @param  {string} action 'log', 'error', 'warn'.
	 * @param  {object} opts Default is same with `kit.inspect`
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

		if typeof msg != 'string'
			console[action] "[#{time}] ->\n" + kit.inspect(msg, opts), time_delta
		else
			console[action] "[#{time}]", msg, time_delta

		if action == 'error'
			console.log "\u0007\n"

	###*
	 * Block terminal and wait for user inputs.
	 * @param  {object} opts See the https://github.com/flatiron/prompt
	 * @return {promise} Contains the results of prompt.
	###
	prompt_get: (opts) ->
		prompt = kit._require 'prompt', (prompt) ->
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
	 * a limitation.
	 * @param  {array} list A list of functions. Each will return a promise.
	 * @param  {int} limit The max task to run at the same time.
	 * @return {promise}
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
	 * A comments parser for coffee-script.
	 * Used to generate documantation automatically.
	 * @param  {string} module_name The name of the module it belongs to.
	 * @param  {string} code Coffee source code.
	 * @return {array} The parsed comments. Something like:
	 * {
	 * 		module: 'nobone'
	 * 		name: 'parse_comment'
	 * 		description: A comments parser for coffee-script.
	 * 		tags: [
	 * 			{
	 * 				tag: 'param'
	 * 				type: 'string'
	 * 				name: 'module_name'
	 * 				description: 'The name of the module it belongs to.'
	 * 			}
	 * 		]
	 * }
	###
	parse_comment: (module_name, code) ->
		comment_reg = /###\*([\s\S]+?)###\s+([\w\.]+)/g
		split_reg = /^\s+\* @/m
		tag_name_reg = /^(\w+)\s*/
		tag_2_reg = /^(\w+)\s*([\s\S]*)/
		tag_3_reg = /^(\w+)\s+\{(\w+)\}\s*([\s\S]*)/
		tag_4_reg = /^(\w+)\s+\{(\w+)\}\s+(\w+)\s*([\s\S]*)/

		parse_info = (block) ->
			arr = block.split(split_reg).map (el) ->
				el.replace(/^.+\* /mg, '').trim()

			description = arr[0]
			tags = arr[1..].map (el) ->
				tag = el.match(tag_name_reg)[1]

				switch tag
					when 'return', 'type'
						m = el.match tag_3_reg
						{
							tag: m[1]
							type: m[2]
							description: m[3]
						}
					when 'param'
						m = el.match tag_4_reg
						{
							tag: m[1]
							type: m[2]
							name: m[3]
							description: m[4]
						}
					else
						m = el.match tag_2_reg
						{
							tag: m[1]
							description: m[2]
						}
			{
				description
				tags
			}

		comments = []
		m = null
		while (m = comment_reg.exec(code)) != null
			info = parse_info m[1]
			comments.push {
				module: module_name
				name: m[2]
				description: info.description
				tags: info.tags
			}

		return comments

	###*
	 * A scaffolding helper to generate template project.
	 * The `lib/cli.coffee` used it as an example.
	 * @param  {object} opts Defaults:
	 * {
	 * 		prompt: null
	 * 		src_dir: null
	 * 		pattern: '**'
	 * 		dest_dir: null
	 * 		compile: (str, data, path) ->
	 * 			ejs = kit._require 'ejs'
	 * 			data.filename = path
	 * 			ejs.render str, data
	 * }
	 * @return {promise}
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
				ejs = kit._require 'ejs'
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