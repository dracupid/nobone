_ = require 'lodash'
http = require 'http'
{ EventEmitter } = require('events')

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
	}

module.exports.defaults = {
	enable_socketio: true
	express: null
}
