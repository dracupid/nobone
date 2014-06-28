## Overview

A server library which will ease you life.

[![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone)


## Install

    npm install nobone


## Usage


```coffeescript
nb = require 'nobone'


port = 8013

# Server
nb.service.get '/', (req, res) ->

	# Renderer
	# You can also render coffee, stylus, or define custom handlers.
	nb.renderer.render('test/sample.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ auto_reload: nb.renderer.auto_reload() })

# Launch socket.io and express.js
# Launch only express.js: "nb.service.listen port"
nb.service.server.listen port

# Kit
# Print out time, log message, time span between two log.
nb.kit.log 'Listen port ' + port

# Static folder to automatically serve coffeescript and stylus.
# nb.service.use nb.renderer.static()

# Log out all the handlers. You can define your own.
console.dir nb.renderer.code_handlers

# Use socket.io to trigger reaload page.
# Edit the 'test/sample.ejs' file, the page should auto reload.
nb.renderer.on 'file_modified', (path) ->
	nb.service.io.emit 'file_modified', path

# Database
# Nobone has a build-in file database.
# For more info see: https://github.com/ysmood/jdb
# Here we save 'a' as value 1.
nb.db.exec({
	command: (jdb) ->
		jdb.doc.a = 1
		jdb.save('OK')
}).done (data) ->
	nb.kit.log data
```


## BSD

May 2014, Yad Smood
