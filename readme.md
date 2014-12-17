[![nobone](assets/img/nobone.png?noboneAssets)](https://github.com/ysmood/nobone)


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

0. Why doesn&#39;t the compiler work properly?

  &gt; Please delete the `.nobone` cache directory, and try again.

0. How to view the documentation with TOC (table of contents) or offline?

  &gt; If you have installed nobone globally,
  &gt; just execute `nobone --doc` or `nobone -d`. If you are on Windows or Mac,
  &gt; it will auto open the documentation.

  &gt; If you have installed nobone with `npm install nobone` in current
  &gt; directory, execute `nodeModules/.bin/nobone -d`.

0. Why I can&#39;t execute the entrance file with nobone cli tool?

  &gt; Don&#39;t execute `nobone` with a directory path when you want to start it with
  &gt; an entrance file.

0. Why doesn&#39;t the auto-reaload work?

  &gt; Check if the `process.env.NODE_ENV` is set to `development`.

0. When serving `jade` or `less`, it doesn&#39;t work.

  &gt; These are optinal packages, you have to install them first.
  &gt; For example, if you want nobone to support `jade`: `npm install -g jade`.

0. How to disable that annoying nobone update warn?

  &gt; There&#39;s an option to do this: `nb = nobone { checkUpgrade: false }`.


*****************************************************************************

## Quick Start

```coffee
process.env.NODE_ENV = &#39;development&#39;

nobone = require &#39;nobone&#39;

port = 8219

# If you want to init without a specific module,
# for example &#39;db&#39; and &#39;service&#39; module, just exclude them:
# 	nobone {
# 		renderer: {}
# 	}
# By default it only loads two modules: `service` and `renderer`.
nb = nobone {
	db: { dbPath: &#39;./test.db&#39; }
	proxy: {}
	renderer: {}
	service: {}
	lang: {
		langPath: &#39;examples/fixtures/lang&#39;
		current: &#39;cn&#39;
	}
}

# Service
nb.service.get &#39;/&#39;, (req, res) -&gt;
	# Renderer
	# It will auto-find the &#39;examples/fixtures/index.tpl&#39;, and render it to html.
	# You can also render jade, coffee, stylus, less, sass, markdown, or define custom handlers.
	# When you modify the `examples/fixtures/index.tpl`, the page will auto-reload.
	nb.renderer.render(&#39;examples/fixtures/index.html&#39;)
	.done (tplFn) -&gt;
		res.send tplFn({ name: &#39;nobone&#39; })

# Launch express.js
nb.service.listen port, -&gt;
	# Kit
	# A smarter log helper.
	nb.kit.log &#39;Listen port &#39; + port

	# Open default browser.
	nb.kit.open &#39;http://127.0.0.1:&#39; + port

# Static folder for auto-service of coffeescript and stylus, etc.
nb.service.use nb.renderer.static(&#39;examples/fixtures&#39;)

# Database
# Nobone has a build-in file database.
# Here we save &#39;a&#39; as value 1.
nb.db.loaded.done -&gt;
	nb.db.exec (db) -&gt;
		db.doc.a = 1
		db.save(&#39;DB OK&#39;)
	.done (data) -&gt;
		nb.kit.log data

	# Get data &#39;a&#39;.
	nb.kit.log nb.db.doc.a

# Proxy
# Proxy path to specific url.
nb.service.get &#39;/proxy.*&#39;, (req, res) -&gt;
	# If you visit &quot;http://127.0.0.1:8013/proxy.js&quot;,
	# it&#39;ll return the &quot;http://127.0.0.1:8013/main.js&quot; from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, &quot;http://127.0.0.1:#{port}/main.&quot; + req.params[0]

# Globalization
nb.kit.log &#39;human&#39;.l # -&gt; &#39;人类&#39;
nb.kit.log &#39;open|formal&#39;.l # -&gt; &#39;开启&#39;
nb.kit.log nb.lang(&#39;find %s men&#39;, [10], &#39;jp&#39;) # -&gt; &#39;10人が見付かる&#39;

close = -&gt;
	# Release all the resources.
	nb.close().done -&gt;
		nb.kit.log &#39;Peacefully closed.&#39;

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

Such as `nobone app.js`, `nobone app.coffee`. It will run the script and if
the script changed, it will automatically restart it.

You can use `nobone -w off app.js` to turn off the watcher.
You can pass a json to the watch list `nobone -w '["a.js", "b.js"]' app.js`.
Any of watched file changed, the program will be restarted.

#### Static Folder Server

Such as `nobone /home/`, it will open a web server for you to browse the folder content. As you edit the html file in the folder, nobone will live
reload the content for you. For css or image file change, it won't refresh the whole page, only js file change will trigger the page reload.

You can use url query `?source` and url hash `#L` to view a source file.
Such as `http://127.0.0.1:8013/app.js?source#L10`,
it will open a html page with syntax highlight.
Or full version `http://127.0.0.1:8013/app.js?source=javascript#L10`

You can use `?gotoDoc` to open a dependencies' markdown file. Such as `jdb/readme.md?gotoDoc`. Nobone will use the node require's algorithm to search for the module recursively.

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

```coffee
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

- #### &lt;a href=&quot;lib/nobone.coffee?source#L9&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 NoBone has several modules and a helper lib.
 **All the modules are optional**.
 Only the `kit` lib is loaded by default and is not optional.
 
 Most of the async functions are implemented with [Promise][Promise].
 [Promise]: https://github.com/petkaantonov/bluebird

- #### &lt;a href=&quot;lib/nobone.coffee?source#L42&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;nobone&lt;/b&gt;&lt;/a&gt;

 Main constructor.

 - **&lt;u&gt;param&lt;/u&gt;**: `modules` { _Object_ }

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

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# Whether to auto-check the version of nobone.
    	checkUpgrade: true
    
    # Whether to enable the sse live reload.
    	autoReload: true
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Object_ }

    A nobone instance.

- #### &lt;a href=&quot;lib/nobone.coffee?source#L81&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;close&lt;/b&gt;&lt;/a&gt;

 Release the resources.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

- #### &lt;a href=&quot;lib/nobone.coffee?source#L102&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;version&lt;/b&gt;&lt;/a&gt;

 Get current nobone version string.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _String_ }

- #### &lt;a href=&quot;lib/nobone.coffee?source#L109&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;checkUpgrade&lt;/b&gt;&lt;/a&gt;

 Check if nobone need to be upgraded.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

- #### &lt;a href=&quot;lib/nobone.coffee?source#L134&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;client&lt;/b&gt;&lt;/a&gt;

 The NoBone client helper.

 - **&lt;u&gt;static&lt;/u&gt;**:

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    The options of the client, defaults:
    ```coffee
    {
    	autoReload: kit.isDevelopment()
    	host: &#39;&#39; # The host of the event source.
    }
    ```

 - **&lt;u&gt;param&lt;/u&gt;**: `useJs` { _Boolean_ }

    By default use html. Default is false.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _String_ }

    The code of client helper.

### kit

- #### &lt;a href=&quot;lib/kit.coffee?source#L8&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 A collection of commonly used functions.
 
 - [API Documentation](https://github.com/ysmood/nokit)
 - [Offline Documentation](?gotoDoc=nokit/readme.md)

### service

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L6&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 It is just a Express.js wrap.

 - **&lt;u&gt;extends&lt;/u&gt;**:  { _Express_ }

    [Ref][express]
    [express]: http://expressjs.com/4x/api.html

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L25&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;service&lt;/b&gt;&lt;/a&gt;

 Create a Service instance.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	autoLog: kit.isDevelopment()
    	enableRemoteLog: kit.isDevelopment()
    	enableSse: kit.isDevelopment()
    	express: {}
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Service_ }

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L41&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;server&lt;/b&gt;&lt;/a&gt;

 The server object of the express object.

 - **&lt;u&gt;type&lt;/u&gt;**:  { _http.Server_ }

    [Ref](http://nodejs.org/api/http.html#httpClassHttpServer)

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L131&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;sse&lt;/b&gt;&lt;/a&gt;

 A Server-Sent Event Manager.
 The namespace of nobone sse is `/nobone-sse`.
 For more info see [Using server-sent events][Using server-sent events].
 NoBone use it to implement the live-reload of web assets.
 [Using server-sent events]: https://developer.mozilla.org/en-US/docs/Server-sentEvents/UsingServer-sentEvents

 - **&lt;u&gt;type&lt;/u&gt;**:  { _SSE_ }

 - **&lt;u&gt;property&lt;/u&gt;**: `sessions` { _Array_ }

    The sessions of connected clients.

 - **&lt;u&gt;property&lt;/u&gt;**: `retry` { _Integer_ }

    The reconnection time to use when attempting to send the event, unit is ms.
    Default is 1000ms.
    A session object is something like:
    ```coffee
    {
    	req  # The express.js req object.
    	res  # The express.js res object.
    }
    ```

 - **&lt;u&gt;example&lt;/u&gt;**:

    You browser code should be something like this:
    ```coffee
    es = new EventSource(&#39;/nobone-sse&#39;)
    es.addEventListener(&#39;eventName&#39;, (e) -&gt;
    	msg = JSON.parse(e.data)
    	console.log(msg)
    ```

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L143&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.sseConnected&lt;/b&gt;&lt;/a&gt;

 This event will be triggered when a sse connection started.
 The event name is a combination of sseConnected and req.path,
 for example: &quot;sseConnected/test&quot;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _sseConnected_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `session` { _SSESession_ }

    The session object of current connection.

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L150&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.sseClose&lt;/b&gt;&lt;/a&gt;

 This event will be triggered when a sse connection closed.

 - **&lt;u&gt;event&lt;/u&gt;**:  { _sseClose_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `session` { _SSESession_ }

    The session object of current connection.

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L158&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;sse.create&lt;/b&gt;&lt;/a&gt;

 Create a sse session.

 - **&lt;u&gt;param&lt;/u&gt;**: `req` { _Express.req_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `res` { _Express.res_ }

 - **&lt;u&gt;return&lt;/u&gt;**:  { _SSESession_ }

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L173&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;session.emit&lt;/b&gt;&lt;/a&gt;

 Emit message to client.

 - **&lt;u&gt;param&lt;/u&gt;**: `event` { _String_ }

    The event name.

 - **&lt;u&gt;param&lt;/u&gt;**: `msg` { _Object | String_ }

    The message to send to the client.

- #### &lt;a href=&quot;lib/modules/service.coffee?source#L200&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;sse.emit&lt;/b&gt;&lt;/a&gt;

 Broadcast a event to clients.

 - **&lt;u&gt;param&lt;/u&gt;**: `event` { _String_ }

    The event name.

 - **&lt;u&gt;param&lt;/u&gt;**: `msg` { _Object | String_ }

    The data you want to emit to session.

 - **&lt;u&gt;param&lt;/u&gt;**:  { _String_ }

    [path] The namespace of target sessions. If not set,
    broadcast to all clients.

### renderer

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L9&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 An abstract renderer for any content, such as source code or image files.
 It automatically uses high performance memory cache.
 This renderer helps nobone to build a **passive compilation architecture**.
 You can run the benchmark to see the what differences it makes.
 Even for huge project the memory usage is negligible.

 - **&lt;u&gt;extends&lt;/u&gt;**:  { _events.EventEmitter_ }

    [Ref](http://nodejs.org/api/events.html#eventsClassEventsEventemitter)

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L80&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;renderer&lt;/b&gt;&lt;/a&gt;

 Create a Renderer instance.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	enableWatcher: kit.isDevelopment()
    	autoLog: kit.isDevelopment()
    
    	# If renderer detects this pattern, it will auto-inject `noboneClient.js`
    	# into the page.
    	injectClientReg: /&lt;html[^&lt;&gt;]*&gt;[\s\S]*&lt;/html&gt;/i
    
    	cacheDir: &#39;.nobone/rendererCache&#39;
    	cacheLimit: 1024
    
    	fileHandlers: {
    		&#39;.html&#39;: {
    			default: true
    			extSrc: [&#39;.tpl&#39;,&#39;.ejs&#39;, &#39;.jade&#39;]
    			extraWatch: { path1: &#39;comment1&#39;, path2: &#39;comment2&#39;, ... } # Extra files to watch.
    			encoding: &#39;utf8&#39; # optional, default is &#39;utf8&#39;
    			dependencyReg: {
    				&#39;.ejs&#39;: /&lt;%[\n\r\s]*include\s+([^\r\n]+)\s*%&gt;/
    				&#39;.jade&#39;: /^\s*(?:include|extends)\s+([^\r\n]+)/
    			}
    			compiler: (str, path, data) -&gt; ...
    		}
    
    		# Simple coffee compiler
    		&#39;.js&#39;: {
    			extSrc: &#39;.coffee&#39;
    			compiler: (str, path) -&gt; ...
    		}
    
    		# Browserify a main entrance file.
    		&#39;.jsb&#39;: {
    			type: &#39;.js&#39;
    			extSrc: &#39;.coffee&#39;
    			dependencyReg: /require\s+([^\r\n]+)/
    			compiler: (str, path) -&gt; ...
    		}
    		&#39;.css&#39;: {
    			extSrc: [&#39;.styl&#39;, &#39;.less&#39;, &#39;.sass&#39;, &#39;.scss&#39;]
    			dependencyReg: {
       			&#39;.styl&#39;: /@(?:import|require)\s+([^\r\n]+)/
    				&#39;.less&#39;: /@import\s*(?:\(\w+\))?\s*([^\r\n]+)/
    				&#39;.sass&#39;: /@import\s+([^\r\n]+)/
    				&#39;.scss&#39;: /@import\s+([^\r\n]+)/
    			}
    			compiler: (str, path) -&gt; ...
    		}
    		&#39;.md&#39;: {
    			type: &#39;html&#39; # Force type, optional.
    			extSrc: [&#39;.md&#39;, &#39;.markdown&#39;]
    			compiler: (str, path) -&gt; ...
    		}
    	}
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Renderer_ }

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L115&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;fileHandlers&lt;/b&gt;&lt;/a&gt;

 You can access all the fileHandlers here.
 Manipulate them at runtime.

 - **&lt;u&gt;type&lt;/u&gt;**:  { _Object_ }

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    # We return js directly.
    renderer.fileHandlers[&#39;.js&#39;].compiler = (str) -&gt; str
    ```

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L121&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;cachePool&lt;/b&gt;&lt;/a&gt;

 The cache pool of the result of `fileHandlers.compiler`

 - **&lt;u&gt;type&lt;/u&gt;**:  { _Object_ }

    Key is the file path.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L128&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;dir&lt;/b&gt;&lt;/a&gt;

 Set a service for listing directory content, similar with the `serve-index` project.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _String | Object_ }

    If it&#39;s a string it represents the rootDir.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Middleware_ }

    Experss.js middleware.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L152&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;static&lt;/b&gt;&lt;/a&gt;

 Set a static directory proxy.
 Automatically compile, cache and serve source files for both deveopment and production.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _String | Object_ }

    If it&#39;s a string it represents the rootDir.
    of this static directory. Defaults:
    ```coffee
    {
    	rootDir: &#39;.&#39;
    
    	# Whether enable serve direcotry index.
    	index: kit.isDevelopment()
    
    	injectClient: kit.isDevelopment()
    
    	# Useful when mapping a normal path to a hashed file.
    	# Such as map &#39;lib/main.js&#39; to &#39;lib/main-jk2x.js&#39;.
    	reqPathHandler: (path) -&gt;
    		decodeURIComponent path
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Middleware_ }

    Experss.js middleware.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L177&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;staticEx&lt;/b&gt;&lt;/a&gt;

 An extra version of `renderer.static`.
 Better support for markdown and source file.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _String | Object_ }

    If it&#39;s a string it represents the rootDir.
    of this static directory. Defaults:
    ```coffee
    {
    	rootDir: &#39;.&#39;
    
    	# Whether enable serve direcotry index.
    	index: kit.isDevelopment()
    
    	injectClient: kit.isDevelopment()
    
    	# Useful when mapping a normal path to a hashed file.
    	# Such as map &#39;lib/main.js&#39; to &#39;lib/main-jk2x.js&#39;.
    	reqPathHandler: (path) -&gt;
    		decodeURIComponent path
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Middleware_ }

    Experss.js middleware.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L205&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;render&lt;/b&gt;&lt;/a&gt;

 Render a file. It will auto-detect the file extension and
 choose the right compiler to handle the content.

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String | Object_ }

    The file path. The path extension should be
    the same with the compiled result file. If it&#39;s an object, it can contain
    any number of following params.

 - **&lt;u&gt;param&lt;/u&gt;**: `ext` { _String_ }

    Force the extension. Optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `data` { _Object_ }

    Extra data you want to send to the compiler. Optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `isCache` { _Boolean_ }

    Whether to cache the result,
    default is true. Optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `reqPath` { _String_ }

    The http request path. Support it will make auto-reload
    more efficient.

 - **&lt;u&gt;param&lt;/u&gt;**: `handler` { _FileHandler_ }

    A custom file handler.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

    Contains the compiled content.

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    # The &#39;a.ejs&#39; file may not exists, it will auto-compile
    # the &#39;a.ejs&#39; or &#39;a.html&#39; to html.
    renderer.render(&#39;a.html&#39;).done (html) -&gt; kit.log(html)
    
    # if the content of &#39;a.ejs&#39; is &#39;&lt;% var a = 10 %&gt;&lt;%= a %&gt;&#39;
    renderer.render(&#39;a.ejs&#39;, &#39;.html&#39;).done (html) -&gt; html == &#39;10&#39;
    renderer.render(&#39;a.ejs&#39;).done (str) -&gt; str == &#39;&lt;% var a = 10 %&gt;&lt;%= a %&gt;&#39;
    ```

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L251&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;close&lt;/b&gt;&lt;/a&gt;

 Release the resources.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L259&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;releaseCache&lt;/b&gt;&lt;/a&gt;

 Release memory cache of a file.

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L275&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.compiled&lt;/b&gt;&lt;/a&gt;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _compiled_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    The compiled file.

 - **&lt;u&gt;param&lt;/u&gt;**: `content` { _String_ }

    Compiled content.

 - **&lt;u&gt;param&lt;/u&gt;**: `handler` { _FileHandler_ }

    The current file handler.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L282&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.compileError&lt;/b&gt;&lt;/a&gt;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _compileError_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    The error file.

 - **&lt;u&gt;param&lt;/u&gt;**: `err` { _Error_ }

    The error info.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L290&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.watchFile&lt;/b&gt;&lt;/a&gt;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _watchFile_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    The path of the file.

 - **&lt;u&gt;param&lt;/u&gt;**: `curr` { _fs.Stats_ }

    Current state.

 - **&lt;u&gt;param&lt;/u&gt;**: `prev` { _fs.Stats_ }

    Previous state.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L296&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.fileDeleted&lt;/b&gt;&lt;/a&gt;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _fileDeleted_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    The path of the file.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L302&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;e.fileModified&lt;/b&gt;&lt;/a&gt;

 - **&lt;u&gt;event&lt;/u&gt;**:  { _fileModified_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    The path of the file.

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L510&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;getCache&lt;/b&gt;&lt;/a&gt;

 Set handler cache.

 - **&lt;u&gt;param&lt;/u&gt;**: `handler` { _FileHandler_ }

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

- #### &lt;a href=&quot;lib/modules/renderer.coffee?source#L539&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;genHandler&lt;/b&gt;&lt;/a&gt;

 Generate a file handler.

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `handler` { _FileHandler_ }

 - **&lt;u&gt;return&lt;/u&gt;**:  { _FileHandler_ }

### rendererWidgets

- #### &lt;a href=&quot;lib/modules/rendererWidgets.coffee?source#L4&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 It use the renderer module to create some handy functions.

- #### &lt;a href=&quot;lib/modules/rendererWidgets.coffee?source#L59&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;compiler&lt;/b&gt;&lt;/a&gt;

 The compiler can handle any type of file.

 - **&lt;u&gt;context&lt;/u&gt;**:  { _FileHandler_ }

    Properties:
    ```coffee
    {
    	ext: String # The current file&#39;s extension.
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
    	# If you use inline source map, this property shouldn&#39;t be set.
    	sourceMap: String or Object
    }
    ```

 - **&lt;u&gt;param&lt;/u&gt;**: `str` { _String_ }

    Source content.

 - **&lt;u&gt;param&lt;/u&gt;**: `path` { _String_ }

    For debug info.

 - **&lt;u&gt;param&lt;/u&gt;**: `data` { _Any_ }

    The data sent from the `render` function.
    when you call the `render` directly. Default is an object:
    ```coffee
    {
    	_: lodash
    	injectClient: kit.isDevelopment()
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

    Promise that contains the compiled content.

### db

- #### &lt;a href=&quot;lib/modules/db.coffee?source#L7&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 See my [jdb][jdb] project.
 
 [Offline Documentation](?gotoDoc=jdb/readme.md)
 [jdb]: https://github.com/ysmood/jdb

- #### &lt;a href=&quot;lib/modules/db.coffee?source#L21&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;db&lt;/b&gt;&lt;/a&gt;

 Create a JDB instance.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	dbPath: &#39;./nobone.db&#39;
    }
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Jdb_ }

- #### &lt;a href=&quot;lib/modules/db.coffee?source#L33&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;jdb.loaded&lt;/b&gt;&lt;/a&gt;

 A promise object that help you to detect when
 the db is totally loaded.

 - **&lt;u&gt;type&lt;/u&gt;**:  { _Promise_ }

### proxy

- #### &lt;a href=&quot;lib/modules/proxy.coffee?source#L7&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 For test, page injection development.
 A cross platform Fiddler alternative.
 Most time used with SwitchySharp.

 - **&lt;u&gt;extends&lt;/u&gt;**:  { _http-proxy.ProxyServer_ }

- #### &lt;a href=&quot;lib/modules/proxy.coffee?source#L19&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;proxy&lt;/b&gt;&lt;/a&gt;

 Create a Proxy instance.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Defaults: `{ }`

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Proxy_ }

    For more, see [node-http-proxy][node-http-proxy]
    [node-http-proxy]: https://github.com/nodejitsu/node-http-proxy

- #### &lt;a href=&quot;lib/modules/proxy.coffee?source#L45&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;url&lt;/b&gt;&lt;/a&gt;

 Use it to proxy one url to another.

 - **&lt;u&gt;param&lt;/u&gt;**: `req` { _http.IncomingMessage_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `res` { _http.ServerResponse_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `url` { _String_ }

    The target url forced to. Optional.
    Such as force &#39;http://test.com/a&#39; to &#39;http://test.com/b&#39;,
    force &#39;http://test.com/a&#39; to &#39;http://other.com/a&#39;,
    force &#39;http://test.com&#39; to &#39;other.com&#39;.

 - **&lt;u&gt;param&lt;/u&gt;**: `opts` { _Object_ }

    Other options. Default:
    ```coffee
    {
    	bps: null # Limit the bandwidth byte per second.
    	globalBps: false # if the bps is the global bps.
    	agent: customHttpAgent
    }
    ```

 - **&lt;u&gt;param&lt;/u&gt;**: `err` { _Function_ }

    Custom error handler.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Promise_ }

- #### &lt;a href=&quot;lib/modules/proxy.coffee?source#L127&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;connect&lt;/b&gt;&lt;/a&gt;

 Http CONNECT method tunneling proxy helper.
 Most times used with https proxing.

 - **&lt;u&gt;param&lt;/u&gt;**: `req` { _http.IncomingMessage_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `sock` { _net.Socket_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `head` { _Buffer_ }

 - **&lt;u&gt;param&lt;/u&gt;**: `host` { _String_ }

    The host force to. It&#39;s optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `port` { _Int_ }

    The port force to. It&#39;s optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `err` { _Function_ }

    Custom error handler.

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    nobone = require &#39;nobone&#39;
    { proxy, service } = nobone { proxy:{}, service: {} }
    
    # Directly connect to the original site.
    service.server.on &#39;connect&#39;, proxy.connect
    ```

- #### &lt;a href=&quot;lib/modules/proxy.coffee?source#L166&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;pac&lt;/b&gt;&lt;/a&gt;

 A pac helper.

 - **&lt;u&gt;param&lt;/u&gt;**: `currHost` { _String_ }

    The current host for proxy server. It&#39;s optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `ruleHandler` { _Function_ }

    Your custom pac rules.
    It gives you three helpers.
    ```coffee
    url # The current client request url.
    host # The host name derived from the url.
    currHost = &#39;PROXY host:port;&#39; # Nobone server host address.
    direct =  &quot;DIRECT;&quot;
    match = (pattern) -&gt; # A function use shExpMatch to match your url.
    proxy = (target) -&gt; # return &#39;PROXY target;&#39;.
    ```

 - **&lt;u&gt;return&lt;/u&gt;**:  { _Function_ }

    Express Middleware.

### lang

- #### &lt;a href=&quot;lib/modules/lang.coffee?source#L4&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;Overview&lt;/b&gt;&lt;/a&gt;

 An string helper for globalization.

- #### &lt;a href=&quot;lib/modules/lang.coffee?source#L58&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;self&lt;/b&gt;&lt;/a&gt;

 It will find the right `key/value` pair in your defined `langSet`.
 If it cannot find the one, it will output the key directly.

 - **&lt;u&gt;param&lt;/u&gt;**: `cmd` { _String_ }

    The original text.

 - **&lt;u&gt;param&lt;/u&gt;**: `args` { _Array_ }

    The arguments for string format. Optional.

 - **&lt;u&gt;param&lt;/u&gt;**: `name` { _String_ }

    The target language name. Optional.

 - **&lt;u&gt;return&lt;/u&gt;**:  { _String_ }

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    { lang } = require(&#39;nobone&#39;)(lang: {})
    lang.langSet =
    	human:
    		cn: &#39;人类&#39;
    		jp: &#39;人間&#39;
    
    	open:
    		cn:
    			formal: &#39;开启&#39; # Formal way to say &#39;open&#39;
    			casual: &#39;打开&#39; # Casual way to say &#39;open&#39;
    
    	&#39;find %s men&#39;: &#39;%s人が見付かる&#39;
    
    lang(&#39;human&#39;, &#39;cn&#39;, langSet) # -&gt; &#39;人类&#39;
    lang(&#39;open|casual&#39;, &#39;cn&#39;, langSet) # -&gt; &#39;打开&#39;
    lang(&#39;find %s men&#39;, [10], &#39;jp&#39;, langSet) # -&gt; &#39;10人が見付かる&#39;
    ```

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    { lang } = require(&#39;nobone&#39;)(
    	lang: { langPath: &#39;lang.coffee&#39; }
    	current: &#39;cn&#39;
    )
    
    &#39;human&#39;.l # &#39;人类&#39;
    &#39;Good weather.&#39;.lang(&#39;jp&#39;) # &#39;日和。&#39;
    
    lang.current = &#39;en&#39;
    &#39;human&#39;.l # &#39;human&#39;
    &#39;Good weather.&#39;.lang(&#39;jp&#39;) # &#39;Good weather.&#39;
    ```

- #### &lt;a href=&quot;lib/modules/lang.coffee?source#L109&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;langSet&lt;/b&gt;&lt;/a&gt;

 Language collections.

 - **&lt;u&gt;type&lt;/u&gt;**:  { _Object_ }

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    { lang } = require(&#39;nobone&#39;)(lang: {})
    lang.langSet = {
    	&#39;cn&#39;: { &#39;human&#39;: &#39;人类&#39; }
    }
    ```

- #### &lt;a href=&quot;lib/modules/lang.coffee?source#L116&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;current&lt;/b&gt;&lt;/a&gt;

 Current default language.

 - **&lt;u&gt;type&lt;/u&gt;**:  { _String_ }

 - **&lt;u&gt;default&lt;/u&gt;**:

    &#39;en&#39;

- #### &lt;a href=&quot;lib/modules/lang.coffee?source#L132&quot; target=&quot;_blank&quot;&gt;&lt;b&gt;load&lt;/b&gt;&lt;/a&gt;

 Load language set and save them into the `langSet`.
 Besides, it will also add properties `l` and `lang` to `String.prototype`.

 - **&lt;u&gt;param&lt;/u&gt;**: `filePath` { _String_ }

    js or coffee files.

 - **&lt;u&gt;example&lt;/u&gt;**:

    ```coffee
    { lang } = require(&#39;nobone&#39;)(lang: {})
    lang.load &#39;assets/lang&#39;
    lang.current = &#39;cn&#39;
    log &#39;test&#39;.l # -&gt; &#39;测试&#39;.
    log &#39;%s persons&#39;.lang([10]) # -&gt; &#39;10 persons&#39;
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


&lt;h3&gt;Memory vs Stream&lt;/h3&gt;
Memory cache is faster than direct file streaming even on SSD machine.
It&#39;s hard to test the real condition, because most of the file system
will cache a file into memory if it being read lot of times.

Type   | Performance
------ | ---------------
memory | 1,225 ops/sec ±3.42% (74 runs sampled)
stream | 933 ops/sec ±3.23% (71 runs sampled)

&lt;h3&gt;crc32 vs jhash&lt;/h3&gt;
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
