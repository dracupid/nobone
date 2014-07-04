_ = require 'lodash'
http = require 'http'
{ EventEmitter } = require('events')

###*
 * It is just a Express.js wrap with build in Socket.io (optional).
 * @param  {Object} opts Defaults:
 * ```coffee
 * {
 * 	enable_socketio: process.env.NODE_ENV == 'development'
 * 	express: {}
 * }```
 * @return {Service <- Express}
###
service = (opts = {}) ->
	_.defaults opts, service.defaults

	express = require 'express'
	srv = express opts.express

	server = http.Server srv

	if opts.enable_socketio
		socketio = require 'socket.io'
		io = socketio server

	_.extend srv, {
		io
		server
		listen: ->
			server.listen.apply server, arguments
		close: (callback) ->
			server.close callback
	}

service.defaults = {
	enable_socketio: process.env.NODE_ENV == 'development'
	express: {}
}

module.exports = service
