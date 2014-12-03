[![nobone](assets/img/nobone.png)](https://github.com/ysmood/nobone)


## Overview

A server library tries to understand what developers really need.

The philosophy behind NoBone is providing possibilities rather than
telling developers what they should do. All the default behaviors are
just examples of how to use NoBone. All the APIs should work together
without pain.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)

*****************************************************************************

## Features

* Code you program, not configure.
* Built for performance.
* Not only a good dev-tool, but also good at production.
* Supports programmable plugins.
* Cross platform.
* Pure js, supports coffee by default.

*****************************************************************************

## Install

Install as an dependency:

```shell
npm install nobone

# View a better nobone documentation than Github readme.
nodeModules/.bin/nobone --doc
```

Or you can install it globally:

```shell
npm i -g nobone

# View a better nobone documentation than Github readme.
nobone -d
```

*****************************************************************************

## FAQ

0. Why doesn't the compiler work properly?

  > Please delete the `.nobone` cache directory, and try again.

0. How to view the documentation with TOC (table of contents) or offline?

  > If you have installed nobone globally,
  > just execute `nobone --doc` or `nobone -d`. If you are on Windows or Mac,
  > it will auto open the documentation.

  > If you have installed nobone with `npm install nobone` in current
  > directory, execute `nodeModules/.bin/nobone -d`.

0. Why I can't execute the entrance file with nobone cli tool?

  > Don't execute `nobone` with a directory path when you want to start it with
  > an entrance file.

0. Why doesn't the auto-reaload work?

  > Check if the `process.env.NODE_ENV` is set to `development`.

0. When serving `jade` or `less`, it doesn't work.

  > These are optinal packages, you have to install them first.
  > For example, if you want nobone to support `jade`: `npm install -g jade`.


*****************************************************************************

## Quick Start

```coffeescript
process.env.NODE_ENV = 'development'

nobone = require 'nobone'

port = 8219

# If you want to init without a specific module,
# for example 'db' and 'service' module, just exclude them:
# 	nobone {
# 		renderer: {}
# 	}
# By default it only loads two modules: `service` and `renderer`.
nb = nobone {
	db: { dbPath: './test.db' }
	proxy: {}
	renderer: {}
	service: {}
	lang: {
		langPath: 'examples/fixtures/lang'
		current: 'cn'
	}
}

# Service
nb.service.get '/', (req, res) ->
	# Renderer
	# It will auto-find the 'examples/fixtures/index.ejs', and render it to html.
	# You can also render jade, coffee, stylus, less, sass, markdown, or define custom handlers.
	# When you modify the `examples/fixtures/index.ejs`, the page will auto-reload.
	nb.renderer.render('examples/fixtures/index.html')
	.done (tplFn) ->
		res.send tplFn({ name: 'nobone' })

# Launch express.js
nb.service.listen port, ->
	# Kit
	# A smarter log helper.
	nb.kit.log 'Listen port ' + port

	# Open default browser.
	nb.kit.open 'http://127.0.0.1:' + port

# Static folder for auto-service of coffeescript and stylus, etc.
nb.service.use nb.renderer.static('examples/fixtures')

# Database
# Nobone has a build-in file database.
# Here we save 'a' as value 1.
nb.db.loaded.done ->
	nb.db.exec (db) ->
		db.doc.a = 1
		db.save('DB OK')
	.done (data) ->
		nb.kit.log data

	# Get data 'a'.
	nb.kit.log nb.db.doc.a

# Proxy
# Proxy path to specific url.
nb.service.get '/proxy.*', (req, res) ->
	# If you visit "http://127.0.0.1:8013/proxy.js",
	# it'll return the "http://127.0.0.1:8013/main.js" from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, "http://127.0.0.1:#{port}/main." + req.params[0]

# Globalization
nb.kit.log 'human'.l # -> '人类'
nb.kit.log 'open|formal'.l # -> '开启'
nb.kit.log nb.lang('find %s men', [10], 'jp') # -> '10人が見付かる'

close = ->
	# Release all the resources.
	nb.close().done ->
		nb.kit.log 'Peacefully closed.'

```

*****************************************************************************

## Tutorials

See the [examples](examples).

*****************************************************************************

## CLI

Install nobone globally: `npm install -g nobone`

```bash
# Help info
nobone -h

# Use it as a static file server for current directory.
# Visit 'http://127.0.0.1/nobone' to see a better nobone documentation.
nobone

# Use regex to filter the log info.
# Print out all the log if it contains '.ejs'
logReg='.ejs' nobone

# Use custom logic to start up.
nobone app.js
watchPersistent=off nobone app.js

# Scaffolding helper
nobone bone -h

```

*****************************************************************************

## Plugin

Here I give a simple instruction. For a real example, see [nobone-sync](https://github.com/ysmood/nobone-sync).

### Package config

NoBone support a simple way to implement npm plugin. And your npm package doesn't have to waist time to install nobone dependencies. The `package.json` file can only have these properties:

```javascript
{
  "name": "nobone-sample",
  "version": "0.0.1",
  "description": "A sample nobone plugin.",
  "main": "main.coffee"
}
```

The `name` of the plugin should prefixed with `nobone-`.

### Main Entrance File

The `main.coffee` file may looks like:

```coffeescript
{ kit } = require 'nobone'
kit.log 'sample plugin'
```

### Use A Plugin

Suppose we have published the `nobone-sampe` plugin with npm.

Other people can use the plugin after installing it with either `npm install nobone-sample` or `npm install -g nobone-sample`.

To run the plugin simply use `nobone sample`.

You can use `nobone ls` to list all installed plugins.

*****************************************************************************

## Modules API

_It's highly recommended reading the API doc locally by command `nobone --doc`_

### nobone

- #### <a href="lib/nobone.coffee#L9" target="_blank"><b>Overview</b></a>

 NoBone has several modules and a helper lib.
 **All the modules are optional**.
 Only the `kit` lib is loaded by default and is not optional.
 
 Most of the async functions are implemented with [Promise][Promise].
 [Promise]: https://github.com/petkaantonov/bluebird

- #### <a href="lib/nobone.coffee#L39" target="_blank"><b>nobone</b></a>

 Main constructor.

 - **<u>param</u>**: `modules` { _Object_ }

    By default, it only load two modules,
    `service` and `renderer`:
    ```coffeescript
    {
    	service: {}
    	renderer: {}
    	db: null
    	proxy: null
    	lang: null
    
    	langPath: null # language set directory
    }
    ```

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	# Whether to auto-check the version of nobone.
    	checkUpgrade: true
    }
    ```

 - **<u>return</u>**:  { _Object_ }

    A nobone instance.

- #### <a href="lib/nobone.coffee#L77" target="_blank"><b>close</b></a>

 Release the resources.

 - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/nobone.coffee#L98" target="_blank"><b>version</b></a>

 Get current nobone version string.

 - **<u>return</u>**:  { _String_ }

- #### <a href="lib/nobone.coffee#L105" target="_blank"><b>checkUpgrade</b></a>

 Check if nobone need to be upgraded.

 - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/nobone.coffee#L130" target="_blank"><b>client</b></a>

 The NoBone client helper.

 - **<u>static</u>**:

 - **<u>param</u>**: `opts` { _Object_ }

    The options of the client, defaults:
    ```coffeescript
    {
    	autoReload: kit.isDevelopment()
    	host: '' # The host of the event source.
    }
    ```

 - **<u>param</u>**: `useJs` { _Boolean_ }

    By default use html. Default is false.

 - **<u>return</u>**:  { _String_ }

    The code of client helper.

### service

- #### <a href="lib/modules/service.coffee#L6" target="_blank"><b>Overview</b></a>

 It is just a Express.js wrap.

 - **<u>extends</u>**:  { _Express_ }

    [Ref][express]
    [express]: http://expressjs.com/4x/api.html

- #### <a href="lib/modules/service.coffee#L25" target="_blank"><b>service</b></a>

 Create a Service instance.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	autoLog: kit.isDevelopment()
    	enableRemoteLog: kit.isDevelopment()
    	enableSse: kit.isDevelopment()
    	express: {}
    }
    ```

 - **<u>return</u>**:  { _Service_ }

- #### <a href="lib/modules/service.coffee#L41" target="_blank"><b>server</b></a>

 The server object of the express object.

 - **<u>type</u>**:  { _http.Server_ }

    [Ref](http://nodejs.org/api/http.html#httpClassHttpServer)

- #### <a href="lib/modules/service.coffee#L131" target="_blank"><b>sse</b></a>

 A Server-Sent Event Manager.
 The namespace of nobone sse is `/nobone-sse`.
 For more info see [Using server-sent events][Using server-sent events].
 NoBone use it to implement the live-reload of web assets.
 [Using server-sent events]: https://developer.mozilla.org/en-US/docs/Server-sentEvents/UsingServer-sentEvents

 - **<u>type</u>**:  { _SSE_ }

 - **<u>property</u>**: `sessions` { _Array_ }

    The sessions of connected clients.

 - **<u>property</u>**: `retry` { _Integer_ }

    The reconnection time to use when attempting to send the event, unit is ms.
    Default is 1000ms.
    A session object is something like:
    ```coffeescript
    {
    	req  # The express.js req object.
    	res  # The express.js res object.
    }
    ```

 - **<u>example</u>**:

    You browser code should be something like this:
    ```coffeescript
    es = new EventSource('/nobone-sse')
    es.addEventListener('eventName', (e) ->
    	msg = JSON.parse(e.data)
    	console.log(msg)
    ```

- #### <a href="lib/modules/service.coffee#L143" target="_blank"><b>e.sseConnected</b></a>

 This event will be triggered when a sse connection started.
 The event name is a combination of sseConnected and req.path,
 for example: "sseConnected/test"

 - **<u>event</u>**:  { _sseConnected_ }

 - **<u>param</u>**: `session` { _SSESession_ }

    The session object of current connection.

- #### <a href="lib/modules/service.coffee#L150" target="_blank"><b>e.sseClose</b></a>

 This event will be triggered when a sse connection closed.

 - **<u>event</u>**:  { _sseClose_ }

 - **<u>param</u>**: `session` { _SSESession_ }

    The session object of current connection.

- #### <a href="lib/modules/service.coffee#L158" target="_blank"><b>sse.create</b></a>

 Create a sse session.

 - **<u>param</u>**: `req` { _Express.req_ }

 - **<u>param</u>**: `res` { _Express.res_ }

 - **<u>return</u>**:  { _SSESession_ }

- #### <a href="lib/modules/service.coffee#L173" target="_blank"><b>session.emit</b></a>

 Emit message to client.

 - **<u>param</u>**: `event` { _String_ }

    The event name.

 - **<u>param</u>**: `msg` { _Object | String_ }

    The message to send to the client.

- #### <a href="lib/modules/service.coffee#L200" target="_blank"><b>sse.emit</b></a>

 Broadcast a event to clients.

 - **<u>param</u>**: `event` { _String_ }

    The event name.

 - **<u>param</u>**: `msg` { _Object | String_ }

    The data you want to emit to session.

 - **<u>param</u>**:  { _String_ }

    [path] The namespace of target sessions. If not set,
    broadcast to all clients.

### renderer

- #### <a href="lib/modules/renderer.coffee#L9" target="_blank"><b>Overview</b></a>

 An abstract renderer for any content, such as source code or image files.
 It automatically uses high performance memory cache.
 This renderer helps nobone to build a **passive compilation architecture**.
 You can run the benchmark to see the what differences it makes.
 Even for huge project the memory usage is negligible.

 - **<u>extends</u>**:  { _events.EventEmitter_ }

    [Ref](http://nodejs.org/api/events.html#eventsClassEventsEventemitter)

- #### <a href="lib/modules/renderer.coffee#L80" target="_blank"><b>renderer</b></a>

 Create a Renderer instance.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	enableWatcher: kit.isDevelopment()
    	autoLog: kit.isDevelopment()
    
    	# If renderer detects this pattern, it will auto-inject `noboneClient.js`
    	# into the page.
    	injectClientReg: /<html[^<>]*>[\s\S]*</html>/i
    
    	cacheDir: '.nobone/rendererCache'
    	cacheLimit: 1024
    
    	fileHandlers: {
    		'.html': {
    			default: true
    			extSrc: ['.ejs', '.jade']
    			extraWatch: { path1: 'comment1', path2: 'comment2', ... } # Extra files to watch.
    			encoding: 'utf8' # optional, default is 'utf8'
    			dependencyReg: {
    				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/
    				'.jade': /^\s*(?:include|extends)\s+([^\r\n]+)/
    			}
    			compiler: (str, path, data) -> ...
    		}
    
    		# Simple coffee compiler
    		'.js': {
    			extSrc: '.coffee'
    			compiler: (str, path) -> ...
    		}
    
    		# Browserify a main entrance file.
    		'.jsb': {
    			type: '.js'
    			extSrc: '.coffee'
    			dependencyReg: /require\s+([^\r\n]+)/
    			compiler: (str, path) -> ...
    		}
    		'.css': {
    			extSrc: ['.styl', '.less', '.sass', '.scss']
    			dependencyReg: {
       			'.styl': /@(?:import|require)\s+([^\r\n]+)/
    				'.less': /@import\s*(?:\(\w+\))?\s*([^\r\n]+)/
    				'.sass': /@import\s+([^\r\n]+)/
    				'.scss': /@import\s+([^\r\n]+)/
    			}
    			compiler: (str, path) -> ...
    		}
    		'.md': {
    			type: 'html' # Force type, optional.
    			extSrc: ['.md', '.markdown']
    			compiler: (str, path) -> ...
    		}
    	}
    }
    ```

 - **<u>return</u>**:  { _Renderer_ }

- #### <a href="lib/modules/renderer.coffee#L115" target="_blank"><b>fileHandlers</b></a>

 You can access all the fileHandlers here.
 Manipulate them at runtime.

 - **<u>type</u>**:  { _Object_ }

 - **<u>example</u>**:

    ```coffeescript
    # We return js directly.
    renderer.fileHandlers['.js'].compiler = (str) -> str
    ```

- #### <a href="lib/modules/renderer.coffee#L121" target="_blank"><b>cachePool</b></a>

 The cache pool of the result of `fileHandlers.compiler`

 - **<u>type</u>**:  { _Object_ }

    Key is the file path.

- #### <a href="lib/modules/renderer.coffee#L128" target="_blank"><b>dir</b></a>

 Set a service for listing directory content, similar with the `serve-index` project.

 - **<u>param</u>**: `opts` { _String | Object_ }

    If it's a string it represents the rootDir.

 - **<u>return</u>**:  { _Middleware_ }

    Experss.js middleware.

- #### <a href="lib/modules/renderer.coffee#L152" target="_blank"><b>static</b></a>

 Set a static directory proxy.
 Automatically compile, cache and serve source files for both deveopment and production.

 - **<u>param</u>**: `opts` { _String | Object_ }

    If it's a string it represents the rootDir.
    of this static directory. Defaults:
    ```coffeescript
    {
    	rootDir: '.'
    
    	# Whether enable serve direcotry index.
    	index: kit.isDevelopment()
    
    	injectClient: kit.isDevelopment()
    
    	# Useful when mapping a normal path to a hashed file.
    	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
    	reqPathHandler: (path) ->
    		decodeURIComponent path
    }
    ```

 - **<u>return</u>**:  { _Middleware_ }

    Experss.js middleware.

- #### <a href="lib/modules/renderer.coffee#L179" target="_blank"><b>render</b></a>

 Render a file. It will auto-detect the file extension and
 choose the right compiler to handle the content.

 - **<u>param</u>**: `path` { _String | Object_ }

    The file path. The path extension should be
    the same with the compiled result file. If it's an object, it can contain
    any number of following params.

 - **<u>param</u>**: `ext` { _String_ }

    Force the extension. Optional.

 - **<u>param</u>**: `data` { _Object_ }

    Extra data you want to send to the compiler. Optional.

 - **<u>param</u>**: `isCache` { _Boolean_ }

    Whether to cache the result,
    default is true. Optional.

 - **<u>param</u>**: `reqPath` { _String_ }

    The http request path. Support it will make auto-reload
    more efficient.

 - **<u>return</u>**:  { _Promise_ }

    Contains the compiled content.

 - **<u>example</u>**:

    ```coffeescript
    # The 'a.ejs' file may not exists, it will auto-compile
    # the 'a.ejs' or 'a.html' to html.
    renderer.render('a.html').done (html) -> kit.log(html)
    
    # if the content of 'a.ejs' is '<% var a = 10 %><%= a %>'
    renderer.render('a.ejs', '.html').done (html) -> html == '10'
    renderer.render('a.ejs').done (str) -> str == '<% var a = 10 %><%= a %>'
    ```

- #### <a href="lib/modules/renderer.coffee#L224" target="_blank"><b>close</b></a>

 Release the resources.

- #### <a href="lib/modules/renderer.coffee#L232" target="_blank"><b>releaseCache</b></a>

 Release memory cache of a file.

 - **<u>param</u>**: `path` { _String_ }

- #### <a href="lib/modules/renderer.coffee#L248" target="_blank"><b>e.compiled</b></a>

 - **<u>event</u>**:  { _compiled_ }

 - **<u>param</u>**: `path` { _String_ }

    The compiled file.

 - **<u>param</u>**: `content` { _String_ }

    Compiled content.

 - **<u>param</u>**: `handler` { _FileHandler_ }

    The current file handler.

- #### <a href="lib/modules/renderer.coffee#L255" target="_blank"><b>e.compileError</b></a>

 - **<u>event</u>**:  { _compileError_ }

 - **<u>param</u>**: `path` { _String_ }

    The error file.

 - **<u>param</u>**: `err` { _Error_ }

    The error info.

- #### <a href="lib/modules/renderer.coffee#L263" target="_blank"><b>e.watchFile</b></a>

 - **<u>event</u>**:  { _watchFile_ }

 - **<u>param</u>**: `path` { _String_ }

    The path of the file.

 - **<u>param</u>**: `curr` { _fs.Stats_ }

    Current state.

 - **<u>param</u>**: `prev` { _fs.Stats_ }

    Previous state.

- #### <a href="lib/modules/renderer.coffee#L269" target="_blank"><b>e.fileDeleted</b></a>

 - **<u>event</u>**:  { _fileDeleted_ }

 - **<u>param</u>**: `path` { _String_ }

    The path of the file.

- #### <a href="lib/modules/renderer.coffee#L275" target="_blank"><b>e.fileModified</b></a>

 - **<u>event</u>**:  { _fileModified_ }

 - **<u>param</u>**: `path` { _String_ }

    The path of the file.

- #### <a href="lib/modules/renderer.coffee#L477" target="_blank"><b>getCache</b></a>

 Set handler cache.

 - **<u>param</u>**: `handler` { _FileHandler_ }

 - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/modules/renderer.coffee#L505" target="_blank"><b>genHandler</b></a>

 Generate a file handler.

 - **<u>param</u>**: `path` { _String_ }

 - **<u>return</u>**:  { _FileHandler_ }

### rendererWidgets

- #### <a href="lib/modules/rendererWidgets.coffee#L4" target="_blank"><b>Overview</b></a>

 It use the renderer module to create some handy functions.

- #### <a href="lib/modules/rendererWidgets.coffee#L61" target="_blank"><b>compiler</b></a>

 The compiler can handle any type of file.

 - **<u>context</u>**:  { _FileHandler_ }

    Properties:
    ```coffeescript
    {
    	ext: String # The current file's extension.
    	opts: Object # The current options of renderer.
    
    	# The file dependencies of current file.
    	# If you set it in the `compiler`, the `dependencyReg`
    	# and `dependencyRoots` should be left undefined.
    	depsList: Array
    
    	# The regex to match dependency path. Regex or Table.
    	dependencyReg: RegExp
    
    	# The root directories for searching dependencies.
    	dependencyRoots: Array
    
    	# The source map informantion.
    	# If you need source map support, the `sourceMap`property
    	# must be set during the compile process.
    	# If you use inline source map, this property shouldn't be set.
    	sourceMap: String or Object
    }
    ```

 - **<u>param</u>**: `str` { _String_ }

    Source content.

 - **<u>param</u>**: `path` { _String_ }

    For debug info.

 - **<u>param</u>**: `data` { _Any_ }

    The data sent from the `render` function.
    when you call the `render` directly. Default is an object:
    ```coffeescript
    {
    	_: lodash
    	injectClient: kit.isDevelopment()
    }
    ```

 - **<u>return</u>**:  { _Promise_ }

    Promise that contains the compiled content.

### db

- #### <a href="lib/modules/db.coffee#L5" target="_blank"><b>Overview</b></a>

 See my [jdb][jdb] project.
 [jdb]: https://github.com/ysmood/jdb

- #### <a href="lib/modules/db.coffee#L19" target="_blank"><b>db</b></a>

 Create a JDB instance.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	dbPath: './nobone.db'
    }
    ```

 - **<u>return</u>**:  { _Jdb_ }

- #### <a href="lib/modules/db.coffee#L31" target="_blank"><b>jdb.loaded</b></a>

 A promise object that help you to detect when
 the db is totally loaded.

 - **<u>type</u>**:  { _Promise_ }

### proxy

- #### <a href="lib/modules/proxy.coffee#L7" target="_blank"><b>Overview</b></a>

 For test, page injection development.
 A cross platform Fiddler alternative.
 Most time used with SwitchySharp.

 - **<u>extends</u>**:  { _http-proxy.ProxyServer_ }

- #### <a href="lib/modules/proxy.coffee#L19" target="_blank"><b>proxy</b></a>

 Create a Proxy instance.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults: `{ }`

 - **<u>return</u>**:  { _Proxy_ }

    For more, see [node-http-proxy][node-http-proxy]
    [node-http-proxy]: https://github.com/nodejitsu/node-http-proxy

- #### <a href="lib/modules/proxy.coffee#L45" target="_blank"><b>url</b></a>

 Use it to proxy one url to another.

 - **<u>param</u>**: `req` { _http.IncomingMessage_ }

 - **<u>param</u>**: `res` { _http.ServerResponse_ }

 - **<u>param</u>**: `url` { _String_ }

    The target url forced to. Optional.
    Such as force 'http://test.com/a' to 'http://test.com/b',
    force 'http://test.com/a' to 'http://other.com/a',
    force 'http://test.com' to 'other.com'.

 - **<u>param</u>**: `opts` { _Object_ }

    Other options. Default:
    ```coffeescript
    {
    	bps: null # Limit the bandwidth byte per second.
    	globalBps: false # if the bps is the global bps.
    	agent: customHttpAgent
    }
    ```

 - **<u>param</u>**: `err` { _Function_ }

    Custom error handler.

 - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/modules/proxy.coffee#L123" target="_blank"><b>connect</b></a>

 Http CONNECT method tunneling proxy helper.
 Most times used with https proxing.

 - **<u>param</u>**: `req` { _http.IncomingMessage_ }

 - **<u>param</u>**: `sock` { _net.Socket_ }

 - **<u>param</u>**: `head` { _Buffer_ }

 - **<u>param</u>**: `host` { _String_ }

    The host force to. It's optional.

 - **<u>param</u>**: `port` { _Int_ }

    The port force to. It's optional.

 - **<u>param</u>**: `err` { _Function_ }

    Custom error handler.

 - **<u>example</u>**:

    ```coffeescript
    nobone = require 'nobone'
    { proxy, service } = nobone { proxy:{}, service: {} }
    
    # Directly connect to the original site.
    service.server.on 'connect', proxy.connect
    ```

- #### <a href="lib/modules/proxy.coffee#L162" target="_blank"><b>pac</b></a>

 A pac helper.

 - **<u>param</u>**: `currHost` { _String_ }

    The current host for proxy server. It's optional.

 - **<u>param</u>**: `ruleHandler` { _Function_ }

    Your custom pac rules.
    It gives you three helpers.
    ```coffeescript
    url # The current client request url.
    host # The host name derived from the url.
    currHost = 'PROXY host:port;' # Nobone server host address.
    direct =  "DIRECT;"
    match = (pattern) -> # A function use shExpMatch to match your url.
    proxy = (target) -> # return 'PROXY target;'.
    ```

 - **<u>return</u>**:  { _Function_ }

    Express Middleware.

### lang

- #### <a href="lib/modules/lang.coffee#L4" target="_blank"><b>Overview</b></a>

 An string helper for globalization.

- #### <a href="lib/modules/lang.coffee#L58" target="_blank"><b>self</b></a>

 It will find the right `key/value` pair in your defined `langSet`.
 If it cannot find the one, it will output the key directly.

 - **<u>param</u>**: `cmd` { _String_ }

    The original text.

 - **<u>param</u>**: `args` { _Array_ }

    The arguments for string format. Optional.

 - **<u>param</u>**: `name` { _String_ }

    The target language name. Optional.

 - **<u>return</u>**:  { _String_ }

 - **<u>example</u>**:

    ```coffeescript
    { lang } = require('nobone')(lang: {})
    lang.langSet =
    	human:
    		cn: '人类'
    		jp: '人間'
    
    	open:
    		cn:
    			formal: '开启' # Formal way to say 'open'
    			casual: '打开' # Casual way to say 'open'
    
    	'find %s men': '%s人が見付かる'
    
    lang('human', 'cn', langSet) # -> '人类'
    lang('open|casual', 'cn', langSet) # -> '打开'
    lang('find %s men', [10], 'jp', langSet) # -> '10人が見付かる'
    ```

 - **<u>example</u>**:

    ```coffeescript
    { lang } = require('nobone')(
    	lang: { langPath: 'lang.coffee' }
    	current: 'cn'
    )
    
    'human'.l # '人类'
    'Good weather.'.lang('jp') # '日和。'
    
    lang.current = 'en'
    'human'.l # 'human'
    'Good weather.'.lang('jp') # 'Good weather.'
    ```

- #### <a href="lib/modules/lang.coffee#L109" target="_blank"><b>langSet</b></a>

 Language collections.

 - **<u>type</u>**:  { _Object_ }

 - **<u>example</u>**:

    ```coffeescript
    { lang } = require('nobone')(lang: {})
    lang.langSet = {
    	'cn': { 'human': '人类' }
    }
    ```

- #### <a href="lib/modules/lang.coffee#L116" target="_blank"><b>current</b></a>

 Current default language.

 - **<u>type</u>**:  { _String_ }

 - **<u>default</u>**:

    'en'

- #### <a href="lib/modules/lang.coffee#L132" target="_blank"><b>load</b></a>

 Load language set and save them into the `langSet`.
 Besides, it will also add properties `l` and `lang` to `String.prototype`.

 - **<u>param</u>**: `filePath` { _String_ }

    js or coffee files.

 - **<u>example</u>**:

    ```coffeescript
    { lang } = require('nobone')(lang: {})
    lang.load 'assets/lang'
    lang.current = 'cn'
    log 'test'.l # -> '测试'.
    log '%s persons'.lang([10]) # -> '10 persons'
    ```

### kit

- #### <a href="lib/kit.coffee#L11" target="_blank"><b>kit</b></a>

 All the async functions in `kit` return promise object.
 Most time I use it to handle files and system staffs.

 - **<u>type</u>**:  { _Object_ }

- #### <a href="lib/kit.coffee#L24" target="_blank"><b>kitExtendsFsPromise</b></a>

 kit extends all the promise functions of [fs-more][fs-more].
 [fs-more]: https://github.com/ysmood/fs-more

 - **<u>example</u>**:

    ```coffeescript
    kit.readFile('test.txt').done (str) ->
    	console.log str
    
    kit.outputFile('a.txt', 'test').done()
    ```

- #### <a href="lib/kit.coffee#L35" target="_blank"><b>_</b></a>

 The lodash lib.

 - **<u>type</u>**:  { _Object_ }

- #### <a href="lib/kit.coffee#L83" target="_blank"><b>async</b></a>

 An throttle version of `Promise.all`, it runs all the tasks under
 a concurrent limitation.

 - **<u>param</u>**: `limit` { _Int_ }

    The max task to run at the same time. It's optional.
    Default is Infinity.

 - **<u>param</u>**: `list` { _Array | Function_ }

    If the list is an array, it should be a list of functions or promises,
    and each function will return a promise.
    If the list is a function, it should be a iterator that returns
    a promise, hen it returns `undefined`, the iteration ends.

 - **<u>param</u>**: `saveResutls` { _Boolean_ }

    Whether to save each promise's result or
    not. Default is true.

 - **<u>param</u>**: `progress` { _Function_ }

    If a task ends, the resolve value will be
    passed to this function.

 - **<u>return</u>**:  { _Promise_ }

 - **<u>example</u>**:

    ```coffeescript
    urls = [
    	'http://a.com'
    	'http://b.com'
    	'http://c.com'
    	'http://d.com'
    ]
    tasks = [
    	-> kit.request url[0]
    	-> kit.request url[1]
    	-> kit.request url[2]
    	-> kit.request url[3]
    ]
    
    kit.async(tasks).then ->
    	kit.log 'all done!'
    
    kit.async(2, tasks).then ->
    	kit.log 'max concurrent limit is 2'
    
    kit.async 3, ->
    	url = urls.pop()
    	if url
    		kit.request url
    .then ->
    	kit.log 'all done!'
    ```

- #### <a href="lib/kit.coffee#L176" target="_blank"><b>compose</b></a>

 Creates a function that is the composition of the provided functions.
 Besides it can also accept async function that returns promise.
 It's more powerful than `_.compose`.

 - **<u>param</u>**: `fns` { _Function | Array_ }

    Functions that return
    promise or any value.
    And the array can also contains promises.

 - **<u>return</u>**:  { _Function_ }

    A composed function that will return a promise.

 - **<u>example</u>**:

    ```coffeescript
    # It helps to decouple sequential pipeline code logic.
    
    createUrl = (name) ->
    	return "http://test.com/" + name
    
    curl = (url) ->
    	kit.request(url).then ->
    		kit.log 'get'
    
    save = (str) ->
    	kit.outputFile('a.txt', str).then ->
    		kit.log 'saved'
    
    download = kit.compose createUrl, curl, save
    # same as "download = kit.compose [createUrl, curl, save]"
    
    download 'home'
    ```

- #### <a href="lib/kit.coffee#L197" target="_blank"><b>daemonize</b></a>

 Daemonize a program.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    {
    	bin: 'node'
    	args: ['app.js']
    	stdout: 'stdout.log'
    	stderr: 'stderr.log'
    }

 - **<u>return</u>**:  { _Porcess_ }

    The daemonized process.

- #### <a href="lib/kit.coffee#L223" target="_blank"><b>decrypt</b></a>

 A simple decrypt helper

 - **<u>param</u>**: `data` { _Any_ }

 - **<u>param</u>**: `password` { _String | Buffer_ }

 - **<u>param</u>**: `algorithm` { _String_ }

    Default is 'aes128'.

 - **<u>return</u>**:  { _Buffer_ }

- #### <a href="lib/kit.coffee#L246" target="_blank"><b>encrypt</b></a>

 A simple encrypt helper

 - **<u>param</u>**: `data` { _Any_ }

 - **<u>param</u>**: `password` { _String | Buffer_ }

 - **<u>param</u>**: `algorithm` { _String_ }

    Default is 'aes128'.

 - **<u>return</u>**:  { _Buffer_ }

- #### <a href="lib/kit.coffee#L267" target="_blank"><b>err</b></a>

 A log error shortcut for `kit.log(msg, 'error', opts)`

 - **<u>param</u>**: `msg` { _Any_ }

 - **<u>param</u>**: `opts` { _Object_ }

- #### <a href="lib/kit.coffee#L288" target="_blank"><b>exec</b></a>

 A better `child_process.exec`.

 - **<u>param</u>**: `cmd` { _String_ }

    Shell commands.

 - **<u>param</u>**: `shell` { _String_ }

    Shell name. Such as `bash`, `zsh`. Optinal.

 - **<u>return</u>**:  { _Promise_ }

    Resolves when the process's stdio is drained.

 - **<u>example</u>**:

    ```coffeescript
    kit.exec """
    a=10
    echo $a
    """
    
    # Bash doesn't support "**" recusive match pattern.
    kit.exec """
    echo **/*.css
    """, 'zsh'
    ```

- #### <a href="lib/kit.coffee#L323" target="_blank"><b>fs</b></a>

 See my project [fs-more][fs-more].
 [fs-more]: https://github.com/ysmood/fs-more

- #### <a href="lib/kit.coffee#L341" target="_blank"><b>generateBone</b></a>

 A scaffolding helper to generate template project.
 The `lib/cli.coffee` used it as an example.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	srcDir: null
    	patterns: '**'
    	destDir: null
    	data: {}
    	compile: (str, data, path) ->
    		compile str
    }
    ```

 - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/kit.coffee#L376" target="_blank"><b>generateNodeModulePaths</b></a>

 Generate a list of module paths from a name and a directory.

 - **<u>param</u>**: `moduleName` { _String_ }

    The module name.

 - **<u>param</u>**: `dir` { _String_ }

    The root path. Default is current working dir.

 - **<u>return</u>**:  { _Array_ }

    Paths

- #### <a href="lib/kit.coffee#L392" target="_blank"><b>glob</b></a>

 See the https://github.com/isaacs/node-glob

 - **<u>param</u>**: `patterns` { _String | Array_ }

    Minimatch pattern.

 - **<u>param</u>**: `opts` { _Object_ }

    The glob options.

 - **<u>return</u>**:  { _Promise_ }

    Contains the path list.

- #### <a href="lib/kit.coffee#L421" target="_blank"><b>jhash</b></a>

 See my [jhash][jhash] project.
 [jhash]: https://github.com/ysmood/jhash

- #### <a href="lib/kit.coffee#L430" target="_blank"><b>inspect</b></a>

 For debugging use. Dump a colorful object.

 - **<u>param</u>**: `obj` { _Object_ }

    Your target object.

 - **<u>param</u>**: `opts` { _Object_ }

    Options. Default:
    { colors: true, depth: 5 }

 - **<u>return</u>**:  { _String_ }

- #### <a href="lib/kit.coffee#L446" target="_blank"><b>isDevelopment</b></a>

 Nobone use it to check the running mode of the app.
 Overwrite it if you want to control the check logic.
 By default it returns the `rocess.env.NODE_ENV == 'development'`.

 - **<u>return</u>**:  { _Boolean_ }

- #### <a href="lib/kit.coffee#L455" target="_blank"><b>isProduction</b></a>

 Nobone use it to check the running mode of the app.
 Overwrite it if you want to control the check logic.
 By default it returns the `rocess.env.NODE_ENV == 'production'`.

 - **<u>return</u>**:  { _Boolean_ }

- #### <a href="lib/kit.coffee#L470" target="_blank"><b>log</b></a>

 A better log for debugging, it uses the `kit.inspect` to log.
 
 You can use terminal command like `logReg='pattern' node app.js` to
 filter the log info.
 
 You can use `logTrace='on' node app.js` to force each log end with a
 stack trace.

 - **<u>param</u>**: `msg` { _Any_ }

    Your log message.

 - **<u>param</u>**: `action` { _String_ }

    'log', 'error', 'warn'.

 - **<u>param</u>**: `opts` { _Object_ }

    Default is same with `kit.inspect`

- #### <a href="lib/kit.coffee#L531" target="_blank"><b>monitorApp</b></a>

 Monitor an application and automatically restart it when file changed.
 When the monitored app exit with error,
 the monitor itself will also exit.
 It will make sure your app crash properly.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	bin: 'node'
    	args: ['app.js']
    	watchList: ['app.js']
    	opts: {} # Such as 'cwd', 'stdio', 'env'
    }
    ```

 - **<u>return</u>**:  { _Process_ }

    The child process.

- #### <a href="lib/kit.coffee#L586" target="_blank"><b>nodeVersion</b></a>

 Node version. Such as `v0.10.23` is `0.1023`, `v0.10.1` is `0.1001`.

 - **<u>type</u>**:  { _Float_ }

- #### <a href="lib/kit.coffee#L604" target="_blank"><b>open</b></a>

 Open a thing that your system can recognize.
 Now only support Windows, OSX or system that installed 'xdg-open'.

 - **<u>param</u>**: `cmd` { _String_ }

    The thing you want to open.

 - **<u>param</u>**: `opts` { _Object_ }

    The options of the node native
    `child_process.exec`.

 - **<u>return</u>**:  { _Promise_ }

    When the child process exits.

 - **<u>example</u>**:

    ```coffeescript
    # Open a webpage with the default browser.
    kit.open 'http://ysmood.org'
    ```

- #### <a href="lib/kit.coffee#L639" target="_blank"><b>pad</b></a>

 String padding helper.

 - **<u>param</u>**: `str` { _Sting | Number_ }

 - **<u>param</u>**: `width` { _Number_ }

 - **<u>param</u>**: `char` { _String_ }

    Padding char. Default is '0'.

 - **<u>return</u>**:  { _String_ }

 - **<u>example</u>**:

    ```coffeescript
    kit.pad '1', 3 # '001'
    ```

- #### <a href="lib/kit.coffee#L685" target="_blank"><b>parseComment</b></a>

 A comments parser for coffee-script.
 Used to generate documentation automatically.
 It will traverse through all the comments.

 - **<u>param</u>**: `moduleName` { _String_ }

    The name of the module it belongs to.

 - **<u>param</u>**: `code` { _String_ }

    Coffee source code.

 - **<u>param</u>**: `path` { _String_ }

    The path of the source code.

 - **<u>param</u>**: `opts` { _Object_ }

    Parser options:
    ```coffeescript
    {
    	commentReg: RegExp
    	splitReg: RegExp
    	tagNameReg: RegExp
    	typeReg: RegExp
    	nameReg: RegExp
    	nameTags: ['param', 'property']
    	descriptionReg: RegExp
    }
    ```

 - **<u>return</u>**:  { _Array_ }

    The parsed comments. Each item is something like:
    ```coffeescript
    {
    	module: 'nobone'
    	name: 'parseComment'
    	description: 'A comments parser for coffee-script.'
    	tags: [
    		{
    			tagName: 'param'
    			type: 'string'
    			name: 'code'
    			description: 'The name of the module it belongs to.'
    			path: 'http://thePathOfSourceCode'
    			index: 256 # The target char index in the file.
    			line: 32 # The line number of the target in the file.
    		}
    	]
    }
    ```

- #### <a href="lib/kit.coffee#L753" target="_blank"><b>path</b></a>

 Node native module

- #### <a href="lib/kit.coffee#L761" target="_blank"><b>promptGet</b></a>

 Block terminal and wait for user inputs. Useful when you need
 in-terminal user interaction.

 - **<u>param</u>**: `opts` { _Object_ }

    See the https://github.com/flatiron/prompt

 - **<u>return</u>**:  { _Promise_ }

    Contains the results of prompt.

- #### <a href="lib/kit.coffee#L777" target="_blank"><b>Promise</b></a>

 The promise lib.

 - **<u>type</u>**:  { _Object_ }

- #### <a href="lib/kit.coffee#L787" target="_blank"><b>require</b></a>

 Much much faster than the native require of node, but
 you should follow some rules to use it safely.

 - **<u>param</u>**: `moduleName` { _String_ }

    Relative moudle path is not allowed!
    Only allow absolute path or module name.

 - **<u>param</u>**: `done` { _Function_ }

    Run only the first time after the module loaded.

 - **<u>return</u>**:  { _Module_ }

    The module that you require.

- #### <a href="lib/kit.coffee#L882" target="_blank"><b>request</b></a>

 A powerful extended combination of `http.request` and `https.request`.

 - **<u>param</u>**: `opts` { _Object_ }

    The same as the [http.request][http.request],
    but with some extra options:
    ```coffeescript
    {
    	url: 'It is not optional, String or Url Object.'
    
    	# Other than return `res` with `res.body`,return `body` directly.
    	body: true
    
    	# Max times of auto redirect. If 0, no auto redirect.
    	redirect: 0
    
    	host: 'localhost'
    	hostname: 'localhost'
    	port: 80
    	method: 'GET'
    	path: '/'
    	headers: {}
    	auth: ''
    	agent: null
    
    	# Set null to use buffer, optional.
    	# It supports GBK, ShiftJIS etc.
    	# For more info, see https://github.com/ashtuchkin/iconv-lite
    	resEncoding: 'auto'
    
    	# It's string, object or buffer, optional. When it's an object,
    	# The request will be 'application/x-www-form-urlencoded'.
    	reqData: null
    
    	# auto end the request.
    	autoEndReq: true
    
    	# Readable stream.
    	# If this option is set, the `headers['content-length']`
    	# should also be set.
    	reqPipe: null
    
    	# Writable stream.
    	resPipe: null
    
    	# The progress of the request.
    	reqProgress: (complete, total) ->
    
    	# The progress of the response.
    	resProgress: (complete, total) ->
    }
    ```
    And if set opts as string, it will be treated as the url.
    [http.request]: http://nodejs.org/api/http.html#httpHttpRequestOptionsCallback

 - **<u>return</u>**:  { _Promise_ }

    Contains the http response object,
    it has an extra `body` property.
    You can also get the request object by using `Promise.req`, for example:
    ```coffeescript
    p = kit.request 'http://test.com'
    p.req.on 'response', (res) ->
    	kit.log res.headers['content-length']
    p.done (body) ->
    	kit.log body # html or buffer
    
    kit.request {
    	url: 'https://test.com/a.mp3'
    	body: false
    	resProgress: (complete, total) ->
    		kit.log "Progress: #{complete} / #{total}"
    }
    .done (res) ->
    	kit.log res.body.length
    	kit.log res.headers
    ```

- #### <a href="lib/kit.coffee#L1069" target="_blank"><b>spawn</b></a>

 A safer version of `child_process.spawn` to run a process on
 Windows or Linux.
 It will automatically add `node_modules/.bin` to the `PATH`
 environment variable.

 - **<u>param</u>**: `cmd` { _String_ }

    Path of an executable program.

 - **<u>param</u>**: `args` { _Array_ }

    CLI arguments.

 - **<u>param</u>**: `opts` { _Object_ }

    Process options.
    Same with the Node.js official doc.
    Default will inherit the parent's stdio.

 - **<u>return</u>**:  { _Promise_ }

    The `promise.process` is the child process object.
    When the child process ends, it will resolve.

- #### <a href="lib/kit.coffee#L1117" target="_blank"><b>url</b></a>

 Node native module

- #### <a href="lib/kit.coffee#L1142" target="_blank"><b>watchFile</b></a>

 Watch a file. If the file changes, the handler will be invoked.
 You can change the polling interval by using `process.env.pollingWatch`.
 Use `process.env.watchPersistent = 'off'` to disable the persistent.
 For samba server, we have to choose `watchFile` other than `watch`.

 - **<u>param</u>**: `path` { _String_ }

    The file path

 - **<u>param</u>**: `handler` { _Function_ }

    Event listener.
    The handler has these params:
    - file path
    - current `fs.Stats`
    - previous `fs.Stats`
    - if its a deletion

 - **<u>param</u>**: `autoUnwatch` { _Boolean_ }

    Auto unwatch the file while file deletion.
    Default is true.

 - **<u>return</u>**:  { _Function_ }

    The wrapped watch listeners.

 - **<u>example</u>**:

    ```coffeescript
    process.env.watchPersistent = 'off'
    kit.watchFile 'a.js', (path, curr, prev, isDeletion) ->
    	if curr.mtime != prev.mtime
    		kit.log path
    ```

- #### <a href="lib/kit.coffee#L1172" target="_blank"><b>watchFiles</b></a>

 Watch files, when file changes, the handler will be invoked.
 It takes the advantage of `kit.watchFile`.

 - **<u>param</u>**: `patterns` { _Array_ }

    String array with minimatch syntax.
    Such as `['*/**.css', 'lib/**/*.js']`.

 - **<u>param</u>**: `handler` { _Function_ }

 - **<u>return</u>**:  { _Promise_ }

    It contains the wrapped watch listeners.

 - **<u>example</u>**:

    ```coffeescript
    kit.watchFiles '*.js', (path, curr, prev, isDeletion) ->
    	kit.log path
    ```

- #### <a href="lib/kit.coffee#L1209" target="_blank"><b>watchDir</b></a>

 Watch directory and all the files in it.
 It supports three types of change: create, modify, move, delete.

 - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffeescript
    {
    	dir: '.'
    	pattern: '**' # minimatch, string or array
    
    	# Whether to watch POSIX hidden file.
    	dot: false
    
    	# If the "path" ends with '/' it's a directory, else a file.
    	handler: (type, path, oldPath) ->
    }
    ```

 - **<u>return</u>**:  { _Promise_ }

 - **<u>example</u>**:

    ```coffeescript
    # Only current folder, and only watch js and css file.
    kit.watchDir {
    	dir: 'lib'
    	pattern: '*.+(js|css)'
    	handler: (type, path) ->
    		kit.log type
    		kit.log path
    
    	# If you use watchDir recursively, you need a global watchedList
    	watchedList: {}
    }
    ```



## Changelog

See the [doc/changelog.md](doc/changelog.md) file.

*****************************************************************************

## Unit Test

  npm test

*****************************************************************************

## Benchmark


<h3>Memory vs Stream</h3>
Memory cache is faster than direct file streaming even on SSD machine.
It's hard to test the real condition, because most of the file system
will cache a file into memory if it being read lot of times.

Type   | Performance
------ | ---------------
memory | 1,225 ops/sec ±3.42% (74 runs sampled)
stream | 933 ops/sec ±3.23% (71 runs sampled)

<h3>crc32 vs jhash</h3>
As we can see, jhash is about 1.5x faster than crc32.
Their results of collision test are nearly the same.

Type         | Performance
------------ | ----------------
crc buffer   | 5,903 ops/sec ±0.52% (100 runs sampled)
crc str      | 54,045 ops/sec ±6.67% (83 runs sampled)
jhash buffer | 9,756 ops/sec ±0.67% (101 runs sampled)
jhash str    | 72,056 ops/sec ±0.36% (94 runs sampled)

Type   | Time    | Collision
------ | ------- | -------------
jhash  | 10.002s | 0.004007480630510286% (15 / 374300)
crc32  | 10.001s | 0.004445855827246745% (14 / 314900)


*****************************************************************************

## Road Map

Decouple libs.

Better test coverage.

*****************************************************************************

## Lisence

### BSD

May 2014, Yad Smood
