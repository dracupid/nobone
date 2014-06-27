
module.exports = ->
	new (require 'jdb') {
		promise: true
		db_path: './.nobone.db'
	}
