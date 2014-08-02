_ = require 'lodash'
app_info = require '../package'

conf = _.defaults {
	port: 8013
}, app_info

_.defaults require('../conf'), conf

module.exports = conf
