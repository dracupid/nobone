###*
 * See my [jdb][jdb] project.
 *
 * [Offline Documentation](?gotoDoc=jdb/readme.md)
 * [jdb]: https://github.com/ysmood/jdb
###
Overview = 'db'

{ _ } = require '../kit'

###*
 * Create a JDB instance.
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	dbPath: './nobone.db'
 * }
 * ```
 * @return {Jdb}
###
db = (opts = {}) ->
	_.defaults opts, {
		dbPath: './nobone.db'
	}

	jdb = new (require 'jdb')

	###*
	 * A promise object that help you to detect when
	 * the db is totally loaded.
	 * @type {Promise}
	###
	jdb.loaded = jdb.init opts

	jdb

module.exports = db
