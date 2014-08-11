###*
 * It is just a Express.js wrap.
 * @extends {Express} [Ref][0]
 * [0]: http://expressjs.com/4x/api.html
###
Overview = 'service'

_ = require 'lodash'
http = require 'http'
kit = require '../kit'

###*
 * Create a Service instance.
 * @param  {Object} opts Defaults:
 * ```coffeescript
 * {
 * 	auto_log: process.env.NODE_ENV == 'development'
 * 	enable_remote_log: process.env.NODE_ENV == 'development'
 * 	enable_sse: process.env.NODE_ENV == 'development'
 * 	express: {}
 * }
 * ```
 * @return {Service}
###
service = (opts = {}) ->
	_.defaults opts, service.defaults

	express = require 'express'
	self = express opts.express

	###*
	 * The server object of the express object.
	 * @type {http.Server} [Ref](http://nodejs.org/api/http.html#http_class_http_server)
	###
	server = http.Server self

	self.e = {}

	self._emit = ->
		if opts.auto_log
			kit.log arguments[0].cyan

		self.emit.apply self, arguments

	_.extend self, {
		server

		listen: ->
			server.listen.apply server, arguments
		close: (callback) ->
			server.close callback
	}

	jhash = new kit.jhash.constructor
	self.set 'etag', (body) ->
		hash = jhash.hash body
		len = body.length.toString(36)
		"W/\"#{len}-#{hash}\""

	if opts.enable_remote_log
		init_remote_log self

	if opts.enable_sse
		init_sse self

	self

service.defaults = {
	auto_log: process.env.NODE_ENV == 'development'
	enable_remote_log: process.env.NODE_ENV == 'development'
	enable_sse: process.env.NODE_ENV == 'development'
	express: {}
}


init_remote_log = (self) ->
	self.post '/nobone-log', (req, res) ->
		data = ''

		req.on 'data', (chunk) ->
			data += chunk

		req.on 'end', ->
			try
				kit.log JSON.parse(data)
				res.status(200).end()
			catch e
				res.status(500).end()


init_sse = (self) ->
	###*
	 * A Server-Sent Event Manager.
	 * The namespace of nobone sse is '/nobone-sse'.
	 * For more info see [Using server-sent events][0].
	 * NoBone use it to implement the auto-reload of the web assets.
	 * [0]: https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events
	 * @property {Array} sessions The sessions of connected clients.
	 * A session object is something like:
	 * ```coffeescript
	 * {
	 * 	req  # The express.js req object.
	 * 	res  # The express.js res object.
	 * }
	 * ```
	 * @example You browser code should be something like this:
	 * ```coffeescript
	 * es = new EventSource('/nobone-sse')
	 * es.addEventListener('event_name', (e) ->
	 * 	msg = JSON.parse(e.data)
	 * 	console.log(msg)
	 * ```
	 * @type {SSE}
	###
	self.sse = {
		sessions: []
	}

	###*
	 * This event will be triggered when a sse connection started.
	 * The event name is a combination of sse_connected and req.path,
	 * for example: "sse_connected/test"
	 * @event sse_connected
	 * @param {SSE_session} session The session object of current connection.
	###
	self.e.sse_connected = 'sse_connected'

	###*
	 * This event will be triggered when a sse connection closed.
	 * @event sse_close
	 * @type {SSE_session} session The session object of current connection.
	###
	self.e.sse_close = 'sse_close'

	###*
	 * Create a sse session.
	 * @param  {Express.req} req
	 * @param  {Express.res} res
	 * @return {SSE_session}
	###
	self.sse.create = (req, res) ->
		session = { req, res }

		req.socket.setTimeout 0
		res.writeHead 200, {
			'Content-Type': 'text/event-stream'
			'Cache-Control': 'no-cache'
			'Connection': 'keep-alive'
		}

		###*
		 * Emit message to client.
		 * @param  {String} event The event name.
		 * @param  {Object | String} msg The message to send to the client.
		###
		session.emit = (event, msg = '') ->
			msg = JSON.stringify msg
			res.write """
			id: #{Date.now()}
			event: #{event}
			data: #{msg}\n\n
			"""

		req.on 'close', ->
			_.remove self.sse.sessions, (el) -> el == session
			session.res.end()

		session.emit 'connect', 'ok'
		session

	self.use '/nobone-sse', (req, res) ->
		session = self.sse.create req, res
		self.sse.sessions.push session
		self._emit self.e.sse_connected + req.path, session

	###*
	 * Broadcast a event to clients.
	 * @param {String} event The event name.
	 * @param {Object | String} msg The data you want to emit to session.
	 * @param {String} [path] The namespace of target sessions. If not set,
	 * broadcast to all clients.
	###
	self.sse.emit = (event, msg, path = '') ->
		for el in self.sse.sessions
			if not path
				el.emit event, msg
			else if el.req.path == path
				el.emit event, msg


module.exports = service
