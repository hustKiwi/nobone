###*
 * See my [jdb][jdb] project.
 * [jdb]: https://github.com/ysmood/jdb
###
Overview = 'db'

_ = require 'lodash'

###*
 * Create a JDB instance.
 * @param  {Object} opts Defaults:
 * ```coffeescript
 * {
 * 	db_path: './nobone.db'
 * }
 * ```
 * @return {Jdb}
###
db = (opts = {}) ->
	_.defaults opts, {
		db_path: './nobone.db'
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
