nobone = require 'nobone'

{ proxy, kit, service } = nobone({
	service: {}
	proxy: {}
})

# Delay http requests.
service.use (req, res) ->
	kit.log req.url

	switch req.url

		# You can force the destination url.
		when 'http://www.baidu.com/img/bdlogo.gif'
			proxy.url req, res, 'http://ysmood.org/favicon.ico'

		# Hack the content.
		when 'http://www.baidu.com'
			kit.request {
				url: req.url
				headers: req.headers
			}
			.done (body) ->
				res.send body.replace(/百度一下/g, 'ys')

		# Limit other connections' max bandwidth to 30KB/s.
		else
			proxy.url req, res, { bps: 30 * 1024 }


# Delay https or websocket requests.
service.server.on 'connect', (req, sock, head) ->
	kit.log req.url
	setTimeout ->
		proxy.connect req, sock, head
	, 1000

service.listen 8123
