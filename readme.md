## Overview

A server library which will ease you development life.

Now NoBone is based on express.js and some other useful libraries.

[![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone)

## Install

    npm install nobone


## Quick Start

```coffeescript
process.env.NODE_ENV = 'development'

nobone = require 'nobone'

port = 8013

# All modules use default options to init.
# If you want don't init a specific module,
# for example 'db' and 'service' module, just exclude it:
#	nb.init {
#		renderer: {}
#	}
# By default it load two module: service, renderer
nb = nobone.create {
	db: { db_path: './test.db' }
	proxy: {}
	renderer: {}
	service: {}
}
# Print all available modules.
nobone.available_modules().done (list) ->
	nb.kit.log 'available_modules'
	nb.kit.log list

# Server
nb.service.get '/', (req, res) ->

	# Renderer
	# You can also render coffee, stylus, or define custom handlers.
	nb.renderer.render('tpl/client/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ auto_reload: nb.renderer.auto_reload() })

# Launch socket.io and express.js
s = nb.service.listen port

# Kit
# Print out time, log message, time span between two log.
nb.kit.log 'Listen port ' + port

# Static folder to automatically serve coffeescript and stylus.
nb.service.use nb.renderer.static({ root_dir: 'tpl/client' })

# Use socket.io to trigger reaload page.
# Edit the 'test/sample.ejs' file, the page should auto reload.
nb.renderer.on 'file_modified', (path) ->
	nb.kit.log 'Modifed: '.cyan + path

# Database
# Nobone has a build-in file database.
# For more info see: https://github.com/ysmood/jdb
# Here we save 'a' as value 1.
nb.kit.log nb.db
nb.db.exec({
	command: (jdb) ->
		jdb.doc.a = 1
		jdb.save('OK')
}).done (data) ->
	nb.kit.log data

# Proxy path to specific url.
# For more info, see here: https://github.com/nodejitsu/node-http-proxy
nb.service.get '/proxy.*', (req, res) ->
	# If you visit "http://127.0.0.1:8013/proxy.js",
	# it'll return the "http://127.0.0.1:8013/sample.js" from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, "http://127.0.0.1:#{port}/sample." + req.params[0]

close = ->
	# Release all the resources.
	nb.close().done ->
		nb.kit.log 'Peacefully closed.'

```


## CLI

Install nobone globally: `npm install -g nobone`

```bash
# Help info
nobone -h

# Use it as a static file server for current directory.
nobone

# Use regex to filter the log info.
# Print out all the log if it contains '.ejs'
log_reg='.ejs' nobone

# Use custom logic to start up.
nobone app.js

# Scaffolding helper
nobone bone -h

```


## Modules

NoBone has four main modules, they are all optional.

### db

See my JDB project: https://github.com/ysmood/jdb

### proxy

For test, page injection development.

### renderer

A abstract renderer for any string resources, such as template, source code, etc.
It automatically uses high performance memory cache. You can run the benchmark to see the what differences it makes. Even for huge project its memory usage is negligible.

### service

It is just a Express.js wrap with build in Socket.io (optional).

### kit

The `kit` lib of NoBone will load by default and is not optinal.
All the async functions in `kit` return promise object.
Most time I use it to handle files and system staffs.


## Road Map

API doc.

Better test coverage.


## BSD

May 2014, Yad Smood
