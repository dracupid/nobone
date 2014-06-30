require 'colors'
_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
glob = require 'glob'

kit = {}

# Denodeify fs.
_.chain(fs)
.functions()
.filter (el) ->
	el.slice(-4) == 'Sync'
.each (name) ->
	name = name.slice(0, -4)
	kit[name] = Q.denodeify fs[name]

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

	spawn: (cmd, args = [], options = {}) ->
		spawn = kit._require 'win-spawn'
		deferred = Q.defer()

		opts = _.defaults options, { stdio: 'inherit' }

		try
			ps = spawn cmd, args, opts
		catch err
			deferred.reject err

		ps.on 'error', (err) ->
			deferred.reject err

		deferred.promise.process = ps

		return deferred.promise

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

		kit.watch_files opts.watch_list, (path, curr, prev) ->
			if curr.mtime != prev.mtime
				kit.log "Reload app, modified: ".yellow + path +
					'\n' + _.times(64, ->'*').join('').yellow
				ps.kill 'SIGINT'
				start()

		kit.log "Monitor: ".yellow + opts.watch_list

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

	watch_files: (patterns, handler) ->
		patterns.forEach (pattern) ->
			kit.glob(pattern).then (paths) ->
				paths.forEach (path) ->
					kit.watch_file path, handler

	env_mode: (mode) ->
		{
			env: _.extend(
				process.env, { NODE_ENV: mode }
			)
		}

	inspect: (obj, opts) ->
		util = kit._require 'util'

		_.defaults opts, { colors: true, depth: 3 }

		str = util.inspect obj, opts

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

	path: require 'path'
	url: require 'url'
	outputFile: Q.denodeify fs.outputFile
	copy: Q.denodeify fs.copy
	remove: Q.denodeify fs.remove
	glob: Q.denodeify glob

}

module.exports = kit