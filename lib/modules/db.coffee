_ = require 'lodash'


module.exports.defaults = {
	promise: true
	db_path: './nobone.db'
}

module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	new (require 'jdb')(opts)
