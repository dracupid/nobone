_ = require 'lodash'

###*
 * See my JDB project: https://github.com/ysmood/jdb
 * @param  {object} opts Defaults:
 * ```coffee
 * {
 * 	promise: true
 * 	db_path: './nobone.db'
 * }```
 * @return {jdb}
###
module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	new (require 'jdb')(opts)

module.exports.defaults = {
	promise: true
	db_path: './nobone.db'
}
