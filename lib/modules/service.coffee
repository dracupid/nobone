_ = require 'lodash'
http = require 'http'
{ EventEmitter } = require('events')

###*
 * It is just a Express.js wrap with build in Socket.io (optional).
 * @param  {object} opts Defaults:
 * <pre>{
 * 	enable_socketio: process.env.NODE_ENV == 'development'
 * 	express: {}
 * }</pre>
 * @return {service}
###
module.exports = (opts = {}) ->
	_.defaults opts, module.exports.defaults

	express = require 'express'
	service = express opts.express

	server = http.Server service

	if opts.enable_socketio
		socketio = require 'socket.io'
		io = socketio server

	_.extend service, {
		io
		server
		listen: ->
			server.listen.apply server, arguments
		close: (callback) ->
			server.close callback
	}

module.exports.defaults = {
	enable_socketio: process.env.NODE_ENV == 'development'
	express: {}
}
