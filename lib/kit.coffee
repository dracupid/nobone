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

		ps = spawn cmd, args, opts

		ps.on 'error', (data) ->
			deferred.reject data

		ps.on 'close', (code) ->
			if code == 0
				deferred.resolve code
			else
				deferred.reject code

		deferred.promise.process = ps

		return deferred.promise

	exists: (path) ->
		deferred = Q.defer()
		fs.exists path, (exists) ->
			deferred.resolve exists
		return deferred.promise

	watch_file: (path, handler) ->
		fs.watchFile(
			path
			{
				persistent: false
				interval: kit.watch_interval or 500
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

	log: (msg, action = 'log') ->
		if not kit.last_log_time
			kit.last_log_time = new Date
			if process.env.LOG
				console.log '>> Log should match:', process.env.LOG
				kit.log_reg = new RegExp(process.env.LOG)

		time = new Date()
		time_delta = (+time - +kit.last_log_time).toString().magenta + 'ms'
		kit.last_log_time = time
		time = time.toJSON().slice(0, -5).replace('T', ' ').grey

		if kit.log_reg and not kit.log_reg.test(msg)
			return

		console[action] "[#{time}]", msg, time_delta

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