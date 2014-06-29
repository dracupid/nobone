require 'colors'
_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
spawn = require 'win-spawn'
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

	spawn: (cmd, args = [], options = {}) ->
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
			app: 'app.coffee'
			watch_list: ['app.coffee']
			mode: 'development'
		}

		ps = null
		start = ->
			ps = kit.spawn(opts.bin, [
				opts.app
			], kit.env_mode opts.mode).process

		start()

		kit.watch_files opts.watch_list, (path, curr, prev) ->
			if curr.mtime != prev.mtime
				kit.log "Reload app, modified: ".yellow + path
				ps.kill 'SIGINT'
				start()

		kit.log "Monitor: ".yellow + opts.app

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

		if action == 'inspect'
			util = require 'util'
			console.log "[#{time}]", time_delta, '\n' + util.inspect(msg, opts)
		else
			console[action] "[#{time}] ", msg, time_delta

		if action == 'error'
			console.log "\u0007\n"

	prompt_get: ->
		prompt = require 'prompt'
		prompt.message = '>> '
		prompt.delimiter = ''

		deferred = Q.defer()
		prompt.get (err, res) ->
			if err
				deferred.reject err
			else
				deferred.resolve res

		deferred.promise

	path: require 'path'
	outputFile: Q.denodeify fs.outputFile
	copy: Q.denodeify fs.copy
	remove: Q.denodeify fs.remove
	glob: Q.denodeify glob

}

module.exports = kit