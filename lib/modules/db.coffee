_ = require 'lodash'

module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	new (require 'jdb')(opts)

module.exports.defaults = {
	promise: true
	db_path: './.nobone2.db'
}
