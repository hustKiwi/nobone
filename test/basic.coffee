process.env.NODE_ENV = 'development'

assert = require 'assert'
http = require 'http'
Q = require 'q'
nb = require '../lib/nobone'

nb.init {
	db: {}
	renderer: {}
	service: {}
}

port = 8022

get = (path) ->
	deferred = Q.defer()

	req = http.request {
		host: '127.0.0.1'
		port: port
		path: path
		method: 'GET'
	}, (res) ->
		data = ''
		res.on 'data', (chunk) ->
			data += chunk

		res.on 'end', ->
			try
				deferred.resolve data
			catch e
				deferred.reject e

	req.end()

	deferred.promise

describe 'Basic:', ->

	nb.service.use nb.renderer.static({ root_dir: 'tpl/client' })

	server = nb.service.listen port
	nb.kit.log 'Listen port: ' + port

	it 'the compiler should work', (tdone) ->

		Q.all([
			get '/main.js'
			get '/default.css'
		])
		.then (results) ->
			assert.equal results[0], "var elem;\n\nelem = document.createElement('h1');\n\nelem.textContent = 'Nobone';\n\ndocument.body.appendChild(elem);\n"
			assert.equal results[1], "h1 {\n  color: #126dd0;\n}\n"
		.then ->
			# Test the watcher
			nb.kit.outputFile 'tpl/client/main.coffee', "console.log 'no'"
		.then ->
			deferred = Q.defer()
			setTimeout(->
				get('/main.js')
				.catch (err) -> deferred.reject err
				.then (code) ->
					deferred.resolve code
			, 1000)
			deferred.promise
		.then (code) ->
			assert.equal code, "console.log('no');\n"
		.then ->
			nb.kit.outputFile 'tpl/client/main.coffee', """
				elem = document.createElement 'h1'
				elem.textContent = 'Nobone'
				document.body.appendChild elem
			"""
		.done ->
			server.close()
			tdone()

	it 'the render should work', (tdone) ->
		nb.renderer.render('tpl/client/index.ejs')
		.done (tpl) ->
			assert.equal tpl({ auto_reload: 'ok' }), '<!DOCTYPE html>\n<html>\n<head>\n\t<title>NoBone</title>\n\t<link rel="stylesheet" type="text/css" href="/default.css">\n</head>\n<body>\n\nok\n<script type="text/javascript" src="/main.js"></script>\n\n</body>\n</html>\n'
			tdone()

	it 'the db should work', (tdone) ->
		nb.db.exec({
			command: (jdb) ->
				jdb.doc.a = 1
				jdb.save()
		}).then ->
			nb.db.exec({
				command: (jdb) ->
					jdb.send jdb.doc.a
			}).then (d) ->
				assert.equal d, 1
				tdone()