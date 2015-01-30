process.env.NODE_ENV = 'development'

nobone = require './nobone'
os = require 'os'

{ kit, renderer, service } = nobone {
	service: {}
	renderer: {
		enableWatcher: true
	}
}
{ _ } = kit

[ host, port, rootDir, openDir ] = process.argv[2..]

guessIP = ->
	ifaces = _.reduce(os.networkInterfaces(), (s, v, k) ->
		s.concat _.filter v, (el) ->
			el.family == 'IPv4' and !el.internal
	, [])

	_.map(ifaces, (el) -> el.address.cyan).join ', '

service.use renderer.staticEx(rootDir)
kit.log "Static folder: " + rootDir

# Favicon.
service.get '/favicon.ico', (req, res) ->
	noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'
	res.sendFile noboneFavicon

service.listen port, host, ->
	kit.log "Public IP: " + guessIP().cyan
	kit.log "Listen: " + "#{host}:#{port}".cyan

	if JSON.parse openDir
		kit.xopen 'http://127.0.0.1:' + port
		.catch(->)
