
if process.env.NODE_ENV == 'development'
	require './logger'

module.exports = {

	service: new (require './service')
	renderer: new (require './renderer')
	kit: require './kit'
	_: require './_'

}
