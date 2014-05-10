require 'coffee-script/register'
os = require './sys/os'

task 'dev', 'Run a development server.', ->
	os.spawn 'node', ['./kit/app_mgr.js', 'dev']

task 'debug', 'Run a development server on debug mode, the app will break on startup.', ->
	os.spawn 'node', ['./kit/app_mgr.js', 'debug']

task 'module', 'Make a new module.', ->
	require './kit/make_module'