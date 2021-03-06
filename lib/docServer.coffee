process.env.NODE_ENV = 'development'

nobone = require './nobone'
{ kit, service, renderer } = nobone()
cs = kit.require 'colors/safe'

noboneDir = kit.path.join __dirname, '..'

service.use renderer.staticEx({
	rootDir: noboneDir
	index: true
})

service.get '/favicon.ico', (req, res) ->
	noboneFavicon = kit.path.join __dirname, '/../assets/img/nobone.png'
	res.sendFile noboneFavicon

module.exports = (opts) ->
	service.listen opts.port, ->
		port = service.server.address().port

		url = "http://127.0.0.1:#{port}/readme.md?offlineMarkdown"

		console.log cs.cyan("Please Visit: ") + url

		if opts.openDir
			kit.xopen url
			.catch(->)
