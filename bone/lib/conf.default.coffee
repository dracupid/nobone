_ = require 'lodash'
appInfo = require '../package'

conf = _.defaults {
	port: 8013
}, appInfo

_.defaults require('../conf'), conf

module.exports = conf
