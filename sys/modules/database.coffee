
require 'jdb'

class NB.Database
	constructor: ->
		@jdb = new JDB.Jdb(
			db_path: NB.conf.db_path
		)

		# Auto compact every week.
		setInterval(->
			@jdb.compact_db_file()
		, 1000 * 60 * 60 * 24 * 7)
