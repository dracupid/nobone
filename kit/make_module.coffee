#! node_modules/.bin/coffee

Q = require 'q'
_ = require 'underscore'
os = require '../sys/os'

namespace = ''
class_name = ''
pname = ''

Q.fcall ->
	os.prompt_get [{
		name: 'namespace'
		description: 'The namespace of the module:'
		default: 'NB'
	}, {
		name: 'class_name'
		description: 'The class name of the module:'
		required: true
		pattern: /[A-Z][a-zA-Z_]+/
	}]
.catch (e) ->
	if e.message == 'canceled'
		console.log "\n>> Canceled."
		process.exit 0
.then (result) ->
	pname = result.class_name.toLowerCase()
	namespace = result.namespace
	class_name = result.class_name

	os.remove pname
.then ->
	os.copy('kit/module_tpl', pname)
.then ->
	Q.all [
		os.rename(
			pname + '/client/css/module_tpl.styl'
			pname + "/client/css/#{pname}.styl"
		)
		os.rename(
			pname + '/client/js/module_tpl.coffee'
			pname + "/client/js/#{pname}.coffee"
		)
		os.rename(
			pname + '/client/ejs/module_tpl.ejs'
			pname + "/client/ejs/#{pname}.ejs"
		)
		os.rename(
			pname + '/module_tpl.coffee'
			pname + "/#{pname}.coffee"
		)
	]
.then ->
	os.readFile(pname + "/#{pname}.coffee", 'utf8')
.then (src) ->
	code = _.template(src, { class_name })
	os.outputFile(pname + "/#{pname}.coffee", code)
.done ->
	console.log '>> Module created: ' + class_name
