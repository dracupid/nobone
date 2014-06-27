_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
graceful = require 'graceful-fs'
spawn = require 'win-spawn'
glob = require 'glob'
prompt = require 'prompt'

prompt = require 'prompt'
prompt.message = '>> '
prompt.delimiter = ''

kit =

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

	watch_files: (patterns, handler) ->
		patterns.forEach (pattern) ->
			kit.glob(pattern).then (paths) ->
				paths.forEach (path) ->
					fs.watchFile(
						path
						{ persistent: false, interval: 500 }
						(curr, prev) ->
							handler(path, curr, prev)
					)

	env_mode: (mode) ->
		{
			env: _.extend(
				process.env, { NODE_ENV: mode }
			)
		}

	path: require 'path'

	# Use graceful-fs to prevent kit max open file limit error.
	readFile: Q.denodeify graceful.readFile
	outputFile: Q.denodeify fs.outputFile
	copy: Q.denodeify fs.copy
	rename: Q.denodeify fs.rename
	remove: Q.denodeify fs.remove
	chmod: Q.denodeify fs.chmod
	glob: Q.denodeify glob
	watchFile: fs.watchFile
	prompt_get: Q.denodeify prompt.get

module.exports = kit