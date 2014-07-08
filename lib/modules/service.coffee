###*
 * It is just a Express.js wrap.
 * @extends {Express}
###
Overview = 'service'

_ = require 'lodash'
http = require 'http'
kit = require '../kit'
emit = null

###*
 * Create a Service instance.
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	enable_sse: process.env.NODE_ENV == 'development'
 * 	express: {}
 * }```
 * @return {Service}
###
service = (opts = {}) ->
	_.defaults opts, service.defaults

	express = require 'express'
	self = express opts.express

	server = http.Server self

	self.e = {}

	emit = ->
		if opts.auto_log
			kit.log arguments[0].cyan

		self.emit.apply self, arguments

	###*
	 * Triggered when a sse connection started.
	 * The event name is a combination of sse_connected and req.path,
	 * for example: "sse_connected/test"
	 * @event sse_connected
	 * @param {SSE_session} The session object of current connection.
	###
	self.e.sse_connected = 'sse_connected'

	###*
	 * When a sse connection closed.
	 * @event sse_close
	 * @type {SSE_session} The session object of current connection.
	###
	self.e.sse_close = 'sse_close'

	_.extend self, {
		server

		listen: ->
			server.listen.apply server, arguments
		close: (callback) ->
			server.close callback
	}

	if opts.enable_sse
		init_sse self

	self

service.defaults = {
	auto_log: process.env.NODE_ENV == 'development'
	enable_sse: process.env.NODE_ENV == 'development'
	express: {}
}


init_sse = (self) ->
	###*
	 * A Server-Sent Event Manager.
	 * The namespace of nobone sse is '/nobone-sse',
	 * @example You browser code should be something like this:
	 * ```coffee
	 * source = EventSource('/nobone-sse')
	 * source.addEventListener('message', function (e) {
	 * 	msg = JSON.parse(e.data)
	 * 	console.log(msg);
	 * });
	 * ```
	 * @type {SSE}
	###
	self.sse = {
		sessions: []
	}

	create_session = (req, res) ->
		session = {
			path: req.path
			req
			res
		}

		###*
		 * Send message to client.
		 * @param  {[type]} msg [description]
		 * @return {[type]}     [description]
		###
		session.send = (msg) ->
			msg = JSON.stringify msg
			res.write """
			id: #{Date.now()}
			data: #{msg}\n\n
			"""

		session

	self.use '/nobone-sse', (req, res) ->
		req.socket.setTimeout Infinity
		req.on 'close', ->
			s = _.remove self.sse.sessions, (el) -> el.res == res
			emit self.e.sse_close + req.path, s[0]

		res.writeHead 200, {
			'Content-Type': 'text/event-stream'
			'Cache-Control': 'no-cache'
			'Connection': 'keep-alive'
		}
		res.write '\n'

		session = create_session req, res
		self.sse.sessions.push session

		emit self.e.sse_connected + req.path, session

	###*
	 * Broadcast a event to all clients.
	 * @param {Object | String} msg The data you want to send to session.
	 * @param {String} [path] The namespace of target sessions.
	###
	self.sse.send = (msg, path) ->
		for el in self.sse.sessions
			if not path
				el.send msg
			else if el.path == path
				el.send msg


module.exports = service
