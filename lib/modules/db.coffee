_ = require 'lodash'

###*
 * See my JDB project: https://github.com/ysmood/jdb
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	promise: true
 * 	db_path: './nobone.db'
 * }```
 * @return {Jdb}
###
db = (opts = {}) ->
	_.defaults opts, db.defaults

	new (require 'jdb')(opts)

db.defaults = {
	promise: true
	db_path: './nobone.db'
}

module.exports = db
