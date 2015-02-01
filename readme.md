[![nobone](assets/img/nobone.png?noboneAssets)](https://github.com/ysmood/nobone)


## Overview

A server library tries to understand what developers really need.

The philosophy behind NoBone is providing possibilities rather than
telling developers what they should do. All the default behaviors are
just examples of how to use NoBone. All the APIs should work together
without pain.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956) [![Deps Up to Date](https://david-dm.org/ysmood/nobone.svg?style=flat)](https://david-dm.org/ysmood/nobone)

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
node_modules/.bin/nobone --doc
```

Or you can install it globally:

```shell
npm i -g nobone

# View a better nobone documentation than Github readme.
nb -d
```

*****************************************************************************

## FAQ


0. Why doesn't the auto-reaload work?

  > Check if the `process.env.NODE_ENV` is set to `development`.

0. Why doesn't the compiler work properly?

  > Please delete the `.nobone` cache directory, and try again.

0. How to view the documentation with TOC (table of contents) or offline?

  > If you have installed nobone globally,
  > just execute `nobone --doc` or `nobone -d`. If you are on Windows or Mac,
  > it will auto open the documentation.

  > If you have installed nobone with `npm install nobone` in current
  > directory, execute `node_modules/.bin/nobone -d`.

0. Why I can't execute the entrance file with nobone cli tool?

  > Don't execute `nobone` with a directory path when you want to start it with
  > an entrance file.

0. When serving `jade` or `less`, it doesn't work.

  > These are optinal packages, you have to install them first.
  > For example, if you want nobone to support `jade`, please execute
  > `npm install -g jade`.

0. How to disable that annoying nobone update warn?

  > There's an option to do this: `nb = nobone null, { checkUpgrade: false }`.


*****************************************************************************

## Quick Start

```coffee
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
	# It will auto-find the 'examples/fixtures/index.tpl', and render it to html.
	# You can also render jade, coffee, stylus, less, sass,markdown,
	# or define custom handlers.
	# When you modify the `examples/fixtures/index.tpl`, the page will auto-reload.
	nb.renderer.render('examples/fixtures/index.html')
	.then (tplFn) ->
		res.send tplFn({ name: 'nobone' })

# Launch express.js
nb.service.listen port, ->
	# Kit
	# A smarter log helper.
	nb.kit.log 'Listen port ' + port

	# Open default browser.
	nb.kit.xopen 'http://127.0.0.1:' + port

# Static folder for auto-service of coffeescript and stylus, etc.
nb.service.use nb.renderer.static('examples/fixtures')

# Database
# Nobone has a build-in file database.
# Here we save 'a' as value 1.
nb.db.loaded.then ->
	nb.db.exec (db) ->
		db.doc.a = 1
		db.save('DB OK')
	.then (data) ->
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
	nb.close().then ->
		nb.kit.log 'Peacefully closed.'

```

*****************************************************************************

## Tutorials

### Code Examples

See the [examples](examples).

- [basic](examples/basic.coffee?source)
- [customCompiler](examples/customCompiler.coffee?source)
- [pac](examples/pac.coffee?source)
- [proxy](examples/proxy.coffee?source)
- [proxyGlobalBandwidth](examples/proxyGlobalBandwidth.coffee?source)
- [threadPool](examples/threadPool.coffee?source)

### CLI Usage

You can use nobone as an alternative of `node` bin or `coffee`, it will auto detect file type and run it properly.

#### Run Script

Such as `nb app.js`, `nb app.coffee`. It will run the script and if
the script changed, it will automatically restart it.

You can use `nb -w off app.js` to turn off the watcher.
You can pass a json to the watch list `nb -w '["a.js", "b.js"]' app.js`.
Any of watched file changed, the program will be restarted.

#### Static Folder Server

Such as `nb /home/`, it will open a web server for you to browse the folder content. As you edit the html file in the folder, nobone will live
reload the content for you. For css or image file change, it won't refresh the whole page, only js file change will trigger the page reload.

You can use url query `?source` and url hash `#L` to view a source file.
Such as `http://127.0.0.1:8013/app.js?source#L10`,
it will open a html page with syntax highlight.
Or full version `http://127.0.0.1:8013/app.js?source=javascript#L10`

You can use `?gotoDoc` to open a dependencies' markdown file. Such as `jdb/readme.md?gotoDoc`. Nobone will use the node require's algorithm to search for the module recursively.

*****************************************************************************

## CLI

Install nobone globally: `npm install -g nobone`

### nb

```bash
# Help info
nb -h

# Use it as a static file server for current directory.
# Visit 'http://127.0.0.1/nobone' to see a better nobone documentation.
nb

# Use regex to filter the log info.
# Print out all the log if it contains '.ejs'
logReg='.ejs' nb

# Use custom logic to start up.
nb app.js
watchPersistent=off nb app.js

# Scaffolding helper
nb bone -h

```

### no

This command is inherited from the `nokit`'s.
For more information:

- [API Documentation](https://github.com/ysmood/nokit)
- [Offline Documentation](?gotoDoc=nokit/readme.md#cli)

```bash
# Run default task
no

# See help
no -h
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

```coffee
{ kit } = require 'nobone'
kit.log 'sample plugin'
```

### Use A Plugin

Suppose we have published the `nobone-sampe` plugin with npm.

Other people can use the plugin after installing it with either `npm install nobone-sample` or `npm install -g nobone-sample`.

To run the plugin simply use `nobone sample`.

You can use `nb ls` to list all installed plugins.

*****************************************************************************

## Modules API

_It's highly recommended reading the API doc locally by command `nb --doc`_

### nobone
- #### **[Overview](lib/nobone.coffee?source#L9)**

    NoBone has several modules and a helper lib.
    **All the modules are optional**.
    Only the `kit` lib is loaded by default and is not optional.

    Most of the async functions are implemented with [Promise][Promise].
    [Promise]: https://github.com/petkaantonov/bluebird

- #### **[nobone](lib/nobone.coffee?source#L41)**

    Main constructor.

    - **<u>param</u>**: `modules` { _Object_ }

        By default, it only load two modules,
        `service` and `renderer`:
        ```coffee
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
        ```coffee
        {
        	# Whether to auto-check the version of nobone.
        	checkUpgrade: true

        # Whether to enable the sse live reload.
        	autoReload: true
        }
        ```

    - **<u>return</u>**: { _Object_ }

        A nobone instance.

- #### **[close](lib/nobone.coffee?source#L81)**

    Release the resources.

    - **<u>return</u>**: { _Promise_ }

- #### **[version](lib/nobone.coffee?source#L102)**

    Get current nobone version string.

    - **<u>return</u>**: { _String_ }

- #### **[checkUpgrade](lib/nobone.coffee?source#L109)**

    Check if nobone need to be upgraded.

    - **<u>return</u>**: { _Promise_ }

- #### **[client](lib/nobone.coffee?source#L135)**

    The NoBone client helper.

    - **<u>static</u>**:

    - **<u>param</u>**: `opts` { _Object_ }

        The options of the client, defaults:
        ```coffee
        {
        	autoReload: kit.isDevelopment()
        	host: '' # The host of the event source.
        }
        ```

    - **<u>param</u>**: `useJs` { _Boolean_ }

        By default use html. Default is false.

    - **<u>return</u>**: { _String_ }

        The code of client helper.

### kit
- #### **[Overview](lib/kit.coffee?source#L8)**

    A collection of commonly used functions.

    - [API Documentation](https://github.com/ysmood/nokit)
    - [Offline Documentation](?gotoDoc=nokit/readme.md)

### service
- #### **[Overview](lib/modules/service.coffee?source#L5)**

    It is just a Express.js wrap.

    - **<u>extends</u>**: { _Express_ }

        [Documentation](http://expressjs.com/4x/api.html)

- #### **[service](lib/modules/service.coffee?source#L24)**

    Create a Service instance.

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	autoLog: kit.isDevelopment()
        	enableRemoteLog: kit.isDevelopment()
        	enableSse: kit.isDevelopment()
        	express: {}
        }
        ```

    - **<u>return</u>**: { _Service_ }

- #### **[server](lib/modules/service.coffee?source#L40)**

    The server object of the express object.

    - **<u>type</u>**: { _http.Server_ }

        [Documentation](http://nodejs.org/api/http.html#httpClassHttpServer)

- #### **[sse](lib/modules/service.coffee?source#L133)**

    A Server-Sent Event Manager.
    The namespace of nobone sse is `/nobone-sse`.
    For more info see [Using server-sent events][Using server-sent events].
    NoBone use it to implement the live-reload of web assets.
    [Using server-sent events]: https://developer.mozilla.org/en-US/docs/Server-sentEvents/UsingServer-sentEvents

    - **<u>type</u>**: { _SSE_ }

    - **<u>property</u>**: `sessions` { _Array_ }

        The sessions of connected clients.

    - **<u>property</u>**: `retry` { _Integer_ }

        The reconnection time to use when attempting to send the event, unit is ms.
        Default is 1000ms.
        A session object is something like:
        ```coffee
        {
        	req  # The express.js req object.
        	res  # The express.js res object.
        }
        ```

    - **<u>example</u>**:

        You browser code should be something like this:
        ```coffee
        es = new EventSource('/nobone-sse')
        es.addEventListener('eventName', (e) ->
        	msg = JSON.parse(e.data)
        	console.log(msg)
        ```

- #### **[e.sseConnected](lib/modules/service.coffee?source#L145)**

    This event will be triggered when a sse connection started.
    The event name is a combination of sseConnected and req.path,
    for example: "sseConnected/test"

    - **<u>event</u>**: { _sseConnected_ }

    - **<u>param</u>**: `session` { _SSESession_ }

        The session object of current connection.

- #### **[e.sseClose](lib/modules/service.coffee?source#L152)**

    This event will be triggered when a sse connection closed.

    - **<u>event</u>**: { _sseClose_ }

    - **<u>param</u>**: `session` { _SSESession_ }

        The session object of current connection.

- #### **[sse.create](lib/modules/service.coffee?source#L160)**

    Create a sse session.

    - **<u>param</u>**: `req` { _Express.req_ }

    - **<u>param</u>**: `res` { _Express.res_ }

    - **<u>return</u>**: { _SSESession_ }

- #### **[session.emit](lib/modules/service.coffee?source#L175)**

    Emit message to client.

    - **<u>param</u>**: `event` { _String_ }

        The event name.

    - **<u>param</u>**: `msg` { _Object | String_ }

        The message to send to the client.

- #### **[sse.emit](lib/modules/service.coffee?source#L202)**

    Broadcast a event to clients.

    - **<u>param</u>**: `event` { _String_ }

        The event name.

    - **<u>param</u>**: `msg` { _Object | String_ }

        The data you want to emit to session.

    - **<u>param</u>**: { _String_ }

        [path] The namespace of target sessions. If not set,
        broadcast to all clients.

### renderer
- #### **[Overview](lib/modules/renderer.coffee?source#L9)**

    An abstract renderer for any content, such as source code or image files.
    It automatically uses high performance memory cache.
    This renderer helps nobone to build a **passive compilation architecture**.
    You can run the benchmark to see the what differences it makes.
    Even for huge project the memory usage is negligible.

    - **<u>extends</u>**: { _events.EventEmitter_ }

        [Documentation](http://nodejs.org/api/events.html#eventsClassEventsEventemitter)

- #### **[renderer](lib/modules/renderer.coffee?source#L73)**

    Create a Renderer instance.

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
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
        			extSrc: ['.tpl','.ejs', '.jade']
        			# Extra files to watch.
        			extraWatch: { path1: 'comment1', path2: 'comment2', ... }
        			encoding: 'utf8' # optional, default is 'utf8'
        			dependencyReg: {
        				'.ejs': /<%[\n\r\s]*include\s+([^\r\n]+)\s*%>/g
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
        			dependencyReg: /require\s+([^\r\n]+)/g
        			compiler: (str, path) -> ...
        		}
        		'.css': {
        			extSrc: ['.styl', '.less', '.sass', '.scss']
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

    - **<u>return</u>**: { _Renderer_ }

- #### **[fileHandlers](lib/modules/renderer.coffee?source#L114)**

    You can access all the fileHandlers here.
    Manipulate them at runtime.

    - **<u>type</u>**: { _Object_ }

    - **<u>example</u>**:

        ```coffee
        { renderer } = nobone()
        renderer.fileHandlers['.css'].compiler = (str, path) ->
        	stylus = kit.requireOptional 'stylus'

        	compile = stylus(str, data).set 'filename', path
        	# Take advantage of the syntax parser.
        	this.dependencyPaths = compile.deps()
        	kit.promisify(compile.render, compile)()
        ```

- #### **[cachePool](lib/modules/renderer.coffee?source#L120)**

    The cache pool of the result of `fileHandlers.compiler`

    - **<u>type</u>**: { _Object_ }

        Key is the file path.

- #### **[dir](lib/modules/renderer.coffee?source#L127)**

    Set a service for listing directory content, similar with the `serve-index` project.

    - **<u>param</u>**: `opts` { _String | Object_ }

        If it's a string it represents the rootDir.

    - **<u>return</u>**: { _Middleware_ }

        Experss.js middleware.

- #### **[static](lib/modules/renderer.coffee?source#L153)**

    Set a static directory proxy.
    Automatically compile, cache and serve source files for both deveopment and production.

    - **<u>param</u>**: `opts` { _String | Object_ }

        If it's a string it represents the rootDir.
        of this static directory. Defaults:
        ```coffee
        {
        	rootDir: '.'

        	# Whether enable serve direcotry index.
        	index: kit.isDevelopment()

        	injectClient: kit.isDevelopment()

        	# Useful when mapping a normal path to a hashed file.
        	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
        	reqPathHandler: decodeURIComponent

        	# Check path such as '../../../../etc/passwd'.
        	isMalicious: ->
        }
        ```

    - **<u>return</u>**: { _Middleware_ }

        Experss.js middleware.

- #### **[staticEx](lib/modules/renderer.coffee?source#L177)**

    An extra version of `renderer.static`.
    Better support for markdown and source file.

    - **<u>param</u>**: `opts` { _String | Object_ }

        If it's a string it represents the rootDir.
        of this static directory. Defaults:
        ```coffee
        {
        	rootDir: '.'

        	# Whether enable serve direcotry index.
        	index: kit.isDevelopment()

        	injectClient: kit.isDevelopment()

        	# Useful when mapping a normal path to a hashed file.
        	# Such as map 'lib/main.js' to 'lib/main-jk2x.js'.
        	reqPathHandler: decodeURIComponent
        }
        ```

    - **<u>return</u>**: { _Middleware_ }

        Experss.js middleware.

- #### **[render](lib/modules/renderer.coffee?source#L205)**

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

    - **<u>param</u>**: `handler` { _FileHandler_ }

        A custom file handler.

    - **<u>return</u>**: { _Promise_ }

        Contains the compiled content.

    - **<u>example</u>**:

        ```coffee
        # The 'a.ejs' file may not exists, it will auto-compile
        # the 'a.ejs' or 'a.html' to html.
        renderer.render('a.html').then (html) -> kit.log(html)

        # if the content of 'a.ejs' is '<% var a = 10 %><%= a %>'
        renderer.render('a.ejs', '.html').then (html) -> html == '10'
        renderer.render('a.ejs').then (str) -> str == '<% var a = 10 %><%= a %>'
        ```

- #### **[close](lib/modules/renderer.coffee?source#L251)**

    Release the resources.

- #### **[releaseCache](lib/modules/renderer.coffee?source#L259)**

    Release memory cache of a file.

    - **<u>param</u>**: `path` { _String_ }

- #### **[e.compiled](lib/modules/renderer.coffee?source#L276)**

    - **<u>event</u>**: { _compiled_ }

    - **<u>param</u>**: `path` { _String_ }

        The compiled file.

    - **<u>param</u>**: `content` { _String_ }

        Compiled content.

    - **<u>param</u>**: `handler` { _FileHandler_ }

        The current file handler.

- #### **[e.compileError](lib/modules/renderer.coffee?source#L283)**

    - **<u>event</u>**: { _compileError_ }

    - **<u>param</u>**: `path` { _String_ }

        The error file.

    - **<u>param</u>**: `err` { _Error_ }

        The error info.

- #### **[e.watchFile](lib/modules/renderer.coffee?source#L291)**

    - **<u>event</u>**: { _watchFile_ }

    - **<u>param</u>**: `path` { _String_ }

        The path of the file.

    - **<u>param</u>**: `curr` { _fs.Stats_ }

        Current state.

    - **<u>param</u>**: `prev` { _fs.Stats_ }

        Previous state.

- #### **[e.fileDeleted](lib/modules/renderer.coffee?source#L297)**

    - **<u>event</u>**: { _fileDeleted_ }

    - **<u>param</u>**: `path` { _String_ }

        The path of the file.

- #### **[e.fileModified](lib/modules/renderer.coffee?source#L303)**

    - **<u>event</u>**: { _fileModified_ }

    - **<u>param</u>**: `path` { _String_ }

        The path of the file.

- #### **[getCache](lib/modules/renderer.coffee?source#L513)**

    Set handler cache.

    - **<u>param</u>**: `handler` { _FileHandler_ }

    - **<u>return</u>**: { _Promise_ }

- #### **[genHandler](lib/modules/renderer.coffee?source#L542)**

    Generate a file handler.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `handler` { _FileHandler_ }

    - **<u>return</u>**: { _FileHandler_ }

### rendererWidgets
- #### **[Overview](lib/modules/rendererWidgets.coffee?source#L4)**

    It use the renderer module to create some handy functions.

- #### **[compiler](lib/modules/rendererWidgets.coffee?source#L59)**

    The compiler can handle any type of file.

    - **<u>context</u>**: { _FileHandler_ }

        Properties:
        ```coffee
        {
        	ext: String # The current file's extension.
        	opts: Object # The current options of renderer.

        	# The file dependencies of current file.
        	# If you set it in the `compiler`, the `dependencyReg`
        	# and `dependencyRoots` should be left undefined.
        	dependencyPaths: Array

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
        ```coffee
        {
        	_: lodash
        	injectClient: kit.isDevelopment()
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        Promise that contains the compiled content.

- #### **[dir](lib/modules/rendererWidgets.coffee?source#L231)**

    Folder middleware.

    - **<u>param</u>**: `opts` { _Object_ }

    - **<u>return</u>**: { _Function_ }

- #### **[static](lib/modules/rendererWidgets.coffee?source#L323)**

    Static middleware.

    - **<u>param</u>**: `renderer` { _Renderer_ }

    - **<u>param</u>**: `opts` { _Object_ }

    - **<u>return</u>**: { _Function_ }

- #### **[staticEx](lib/modules/rendererWidgets.coffee?source#L408)**

    Static middleware. Don't use it in production.

    - **<u>param</u>**: `renderer` { _Renderer_ }

    - **<u>param</u>**: `opts` { _Object_ }

    - **<u>return</u>**: { _Function_ }

### db
- #### **[Overview](lib/modules/db.coffee?source#L7)**

    See my [jdb][jdb] project.

    [Offline Documentation](?gotoDoc=jdb/readme.md)
    [jdb]: https://github.com/ysmood/jdb

- #### **[db](lib/modules/db.coffee?source#L21)**

    Create a JDB instance.

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	dbPath: './nobone.db'
        }
        ```

    - **<u>return</u>**: { _Jdb_ }

- #### **[jdb.loaded](lib/modules/db.coffee?source#L33)**

    A promise object that help you to detect when
    the db is totally loaded.

    - **<u>type</u>**: { _Promise_ }

### proxy
- #### **[Overview](lib/modules/proxy.coffee?source#L5)**

    For test, page injection development.
    A cross-platform programmable Fiddler alternative.

- #### **[proxy](lib/modules/proxy.coffee?source#L16)**

    Create a Proxy instance.

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults: `{ }`

    - **<u>return</u>**: { _Proxy_ }

- #### **[url](lib/modules/proxy.coffee?source#L68)**

    Use it to proxy one url to another.

    - **<u>param</u>**: `req` { _http.IncomingMessage_ }

        Also supports Express.js.

    - **<u>param</u>**: `res` { _http.ServerResponse_ }

        Also supports Express.js.

    - **<u>param</u>**: `url` { _String_ }

        The target url forced to. Optional.
        Such as force 'http://test.com/a' to 'http://test.com/b',
        force 'http://test.com/a' to 'http://other.com/a',
        force 'http://test.com' to 'other.com'.

    - **<u>param</u>**: `opts` { _Object_ }

        Other options. Default:
        ```coffee
        {
        	# Limit the bandwidth byte per second.
        	bps: null

        	# if the bps is the global bps.
        	globalBps: false

        	agent: customHttpAgent

        	# You can hack the headers before the proxy send it.
        	handleReqHeaders: (headers) -> headers
        	handleResHeaders: (headers) -> headers
        }
        ```

    - **<u>param</u>**: `err` { _Function_ }

        Custom error handler.

    - **<u>return</u>**: { _Promise_ }

    - **<u>example</u>**:

        ```coffee
        nobone = require 'nobone'
        { proxy, service } = nobone { proxy:{}, service: {} }

        service.post '/a', (req, res) ->
        	proxy.url req, res, 'a.com', (err) ->
        		kit.log err

        service.get '/b', (req, res) ->
        	proxy.url req, res, '/c'

        service.get '/a.js', (req, res) ->
        	proxy.url req, res, 'http://b.com/c.js'

        # Transparent proxy.
        service.use proxy.url
        ```

- #### **[connect](lib/modules/proxy.coffee?source#L162)**

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

        ```coffee
        nobone = require 'nobone'
        { proxy, service } = nobone { proxy:{}, service: {} }

        # Directly connect to the original site.
        service.server.on 'connect', proxy.connect
        ```

- #### **[pac](lib/modules/proxy.coffee?source#L214)**

    A pac helper.

    - **<u>param</u>**: `currHost` { _String_ }

        The current host for proxy server. It's optional.

    - **<u>param</u>**: `ruleHandler` { _Function_ }

        Your custom pac rules.
        It gives you three helpers.
        ```coffee
        url # The current client request url.
        host # The host name derived from the url.
        currHost = 'PROXY host:port;' # Nobone server host address.
        direct =  "DIRECT;"
        match = (pattern) -> # A function use shExpMatch to match your url.
        proxy = (target) -> # return 'PROXY target;'.
        ```

    - **<u>return</u>**: { _Function_ }

        Express Middleware.
        ```coffee
        nobone = require 'nobone'
        { proxy, service } = nobone { proxy:{}, service: {} }

        service.get '/pac', proxy.pac ->
        	if match 'http://a.com/*'
        		currHost
        	else if url == 'http://c.com'
        		proxy 'd.com:8123'
        	else
        		direct
        ```

### lang
- #### **[Overview](lib/modules/lang.coffee?source#L4)**

    An string helper for globalization.

- #### **[self](lib/modules/lang.coffee?source#L58)**

    It will find the right `key/value` pair in your defined `langSet`.
    If it cannot find the one, it will output the key directly.

    - **<u>param</u>**: `cmd` { _String_ }

        The original text.

    - **<u>param</u>**: `args` { _Array_ }

        The arguments for string format. Optional.

    - **<u>param</u>**: `name` { _String_ }

        The target language name. Optional.

    - **<u>return</u>**: { _String_ }

    - **<u>example</u>**:

        ```coffee
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

        ```coffee
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

- #### **[langSet](lib/modules/lang.coffee?source#L109)**

    Language collections.

    - **<u>type</u>**: { _Object_ }

    - **<u>example</u>**:

        ```coffee
        { lang } = require('nobone')(lang: {})
        lang.langSet = {
        	'cn': { 'human': '人类' }
        }
        ```

- #### **[current](lib/modules/lang.coffee?source#L116)**

    Current default language.

    - **<u>type</u>**: { _String_ }

    - **<u>default</u>**:

        'en'

- #### **[load](lib/modules/lang.coffee?source#L132)**

    Load language set and save them into the `langSet`.
    Besides, it will also add properties `l` and `lang` to `String.prototype`.

    - **<u>param</u>**: `filePath` { _String_ }

        js or coffee files.

    - **<u>example</u>**:

        ```coffee
        { lang } = require('nobone')(lang: {})
        lang.load 'assets/lang'
        lang.current = 'cn'
        log 'test'.l # -> '测试'.
        log '%s persons'.lang([10]) # -> '10 persons'
        ```



## Changelog

See the [doc/changelog.md](doc/changelog.md) file.

*****************************************************************************

## Unit Test

```shell
npm test
```

*****************************************************************************

## Benchmark

Goto see [benchmark](benchmark)

*****************************************************************************

## Road Map

Decouple libs.

Better test coverage.

*****************************************************************************

## Lisence

### BSD

May 2014, Yad Smood
