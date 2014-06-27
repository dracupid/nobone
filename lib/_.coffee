require 'colors'
_ = require 'lodash'

last_time = new Date

if process.env.LOG
	console.log '>> Log should match:', process.env.LOG
	log_reg = new RegExp process.env.LOG

_.mixin {

	log: (msg, action = 'log') ->
		time = new Date()
		time_delta = (+time - +last_time).toString().magenta + 'ms'
		last_time = time
		time = time.toJSON().slice(0, -5).replace('T', ' ').grey

		if log_reg and not log_reg.test(msg)
			return

		console[action] "[#{time}]", msg, time_delta

		if action == 'error'
			console.log "\u0007\n"

}

module.exports = _
