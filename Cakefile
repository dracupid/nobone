require 'coffee-script/register'
os = require './sys/os'

task 'dev', 'Make a new module', ->
	os.spawn 'node', ['./kit/app_mgr.js', 'dev']

task 'module', 'Make a new module', ->
	require './kit/make_module'