_ = require 'lodash'
express = require 'express'
http = require 'http'
socketio = require 'socket.io'
{ EventEmitter } = require('events')


create_service = ->
	service = express()

	server = http.Server service
	io = socketio server
	emitter = new EventEmitter

	_.extend service, {
		io
		server
	}

module.exports = create_service
