###*
 * NoBone has four main modules: `renderer`, `service`, `proxy`, `db`, and a helper `kit`.
 * They are all optional.
###
Overview = 'nobone'

_ = require 'lodash'
kit = require './kit'
Q = require 'q'


###*
 * Main constructor.
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	db: null
 * 	proxy: null
 * 	service: {}
 * 	renderer: {}
 * }```
 * @return {Object} A nobone instance.
###
nobone = (opts) ->
	opts ?= {
		db: null
		proxy: null
		service: {}
		renderer: {}
	}

	nb = {
		kit
	}

	for k, v of opts
		if opts[k]
			nb[k] = require('./modules/' + k)(v)

	if nb.service and nb.service.sse and nb.renderer
		nb.renderer.on 'file_modified', (path, ext_bin, req_path) ->
			nb.service.sse.emit(
				'file_modified'
				{ path, ext_bin, req_path }
				'/auto_reload'
			)

	###*
	 * Release the resources.
	 * @return {Promise}
	###
	close = ->
		Q.all _.map(opts, (v, k) ->
			mod = nb[k]
			if v and mod.close
				if mod.close.length > 0
					Q.ninvoke mod, 'close'
				else
					mod.close()
		)
	nb.close = close

	nb

_.extend nobone, {

	kit

	###*
	 * Help you to get the default options of moduels.
	 * @static
	 * @param {String} name Module name, if not set, return all modules' defaults.
	 * @return {Promise} A promise object which will produce the defaults.
	###
	module_defaults: (name) ->
		kit.glob(__dirname + '/modules/*')
		.then (paths) ->
			list = []
			paths.forEach (p) ->
				ext = kit.path.extname p
				mod = kit.path.basename p, ext
				list[mod] = (require './modules/' + mod).defaults

			if name
				list[name]
			else
				list

	###*
	 * The NoBone client helper.
	 * @static
	 * @param {Boolean} auto If true, and not on development mode
	 * return an empty string.
	 * @return {String} The html of client helper.
	###
	client: (auto = true) ->
		if auto and process.env.NODE_ENV != 'development'
			return ''

		if not nobone.client_cache
			fs = kit.require 'fs'
			js = fs.readFileSync(__dirname + '/../dist/nobone_client.js')
			html = """
				\n\n<!-- Nobone Client Helper -->
				<script type="text/javascript">
				#{js}
				</script>\n\n
			"""
			nobone.client_cache = html

		nobone.client_cache
}

module.exports = nobone
