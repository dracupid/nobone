![nobone](https://raw.githubusercontent.com/ysmood/nobone/master/assets/img/nobone.png)


## Overview

A server library ties to understand what developers really need.

The philosophy behind NoBone is providing possibilities rather than
telling developers what they should do. All the default behaviors are
just examples of how to use NoBone. All the APIs should dance together
happily. So other than js, the idea should be port to any other language easily.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)


## Features

* Make you program, not configure.
* Build for performance.
* Cross platform of course.


## Install

    npm install nobone


## Quick Start

```coffee
process.env.NODE_ENV = 'development'

nobone = require 'nobone'

port = 8013

# All modules use default options to init.
# If you want don't init a specific module,
# for example 'db' and 'service' module, just exclude it:
#	nobone {
#		renderer: {}
#	}
# By default it loads two modules: service, renderer
nb = nobone {
	db: { db_path: './test.db' }
	proxy: {}
	renderer: {}
	service: {}
}

# Print all available modules.
nobone.module_defaults().done (list) ->
	nb.kit.log 'module_defaults'
	nb.kit.log list

# Server
nb.service.get '/', (req, res) ->
	# Renderer
	# You can also render coffee, stylus, less, markdown, or define custom handlers.
	nb.renderer.render('bone/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ body: nobone.client() })

# Launch socket.io and express.js
nb.service.listen port

# Kit
# Print out time, log message, time span between two log.
nb.kit.log 'Listen port ' + port

# Static folder to automatically serve coffeescript and stylus.
nb.service.use nb.renderer.static('bone/client')

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

# Proxy
# Proxy path to specific url.
# For more info, see here: https://github.com/nodejitsu/node-http-proxy
nb.service.get '/proxy.*', (req, res) ->
	# If you visit "http://127.0.0.1:8013/proxy.js",
	# it'll return the "http://127.0.0.1:8013/main.js" from the remote server,
	# though here we just use a local server for test.
	nb.proxy.url req, res, "http://127.0.0.1:#{port}/main." + req.params[0]

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
# Visit 'http://127.0.0.1/nobone' to see a better nobone documentation.
nobone

# Use regex to filter the log info.
# Print out all the log if it contains '.ejs'
log_reg='.ejs' nobone

# Use custom logic to start up.
nobone app.js

# Scaffolding helper
nobone bone -h

```


## Modules API

NoBone has four main modules, they are all optional.




<h3>db</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/db.coffee#L4">
				
				<b>Overview</b>
			</a>
		</h4>
		<p><p>See my JDB project: <a href="https://github.com/ysmood/jdb">https://github.com/ysmood/jdb</a></p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/db.coffee#L18">
				
				<b>db</b>
			</a>
		</h4>
		<p><p>Create a JDB instance.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    promise: true
    db_path: &#39;./nobone.db&#39;
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Jdb }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>proxy</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L7">
				
				<b>Overview</b>
			</a>
		</h4>
		<p><p>For test, page injection development.
A cross platform Fiddler alternative.
Most time used with SwitchySharp.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>extends</u>:
					
					<em>{ http-proxy.ProxyServer }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L19">
				
				<b>proxy</b>
			</a>
		</h4>
		<p><p>Create a Proxy instance.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults: <code>{ }</code></p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Proxy }</em>
				</b></p>
				<p><p>For more, see <a href="https://github.com/nodejitsu/node-http-proxy">https://github.com/nodejitsu/node-http-proxy</a></p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L33">
				
				<b>url</b>
			</a>
		</h4>
		<p><p>Use it to proxy one url to another.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>req</code>
					
					<em>{ http.IncomingMessage }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>res</code>
					
					<em>{ http.ServerResponse }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>url</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The target url</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Other options.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>err</code>
					
					<em>{ Function }</em>
				</b></p>
				<p><p>Error handler.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L56">
				
				<b>delay</b>
			</a>
		</h4>
		<p><p>Simulate simple network delay.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>req</code>
					
					<em>{ http.IncomingMessage }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>res</code>
					
					<em>{ http.ServerResponse }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>delay</code>
					
					<em>{ Number }</em>
				</b></p>
				<p><p>In milliseconds.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Other options.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>err</code>
					
					<em>{ Function }</em>
				</b></p>
				<p><p>Error handler.</p>
</p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>renderer</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L8">
				
				<b>Overview</b>
			</a>
		</h4>
		<p><p>A abstract renderer for any string resources, such as template, source content, etc.
It automatically uses high performance memory cache.
You can run the benchmark to see the what differences it makes.
Even for huge project its memory usage is negligible.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>extends</u>:
					
					<em>{ events.EventEmitter }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L61">
				
				<b>renderer</b>
			</a>
		</h4>
		<p><p>Create a Renderer instance.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Example:</p>
<pre><code class="lang-coffee">{
    enable_watcher: process.env.NODE_ENV == &#39;development&#39;
    auto_log: process.env.NODE_ENV == &#39;development&#39;
    file_handlers: {
        &#39;.html&#39;: {
            default: true
            ext_src: &#39;.ejs&#39;
            watch_list: {
                &#39;path&#39;: [pattern1, ...] # Extra files to watch.
            }
            encoding: &#39;utf8&#39; # optional, default is &#39;utf8&#39;
            compiler: (str, path, ext_src, data) -&gt; ...
        }
        &#39;.js&#39;: {
            ext_src: &#39;.coffee&#39;
            compiler: (str, path) -&gt; ...
        }
        &#39;.css&#39;: {
            ext_src: [&#39;.styl&#39;, &#39;.less&#39;]
            compiler: (str, path) -&gt; ...
        }
        &#39;.md&#39;: {
            type: &#39;html&#39; # Force type, optional.
            compiler: (str, path) -&gt; ...
        }
        &#39;.jpg&#39;: {
            encoding: null # To use buffer.
            compiler: (buf) -&gt; buf
        }
        &#39;.png&#39;: {
            encoding: null # To use buffer.
            compiler: &#39;.jpg&#39; # Use the compiler of &#39;.jpg&#39;
        }
        &#39;.gif&#39; ...
    }
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Renderer }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L80">
				
				<b>compiler</b>
			</a>
		</h4>
		<p><p>The compiler should fulfil two interface.
It should return a promise object. Only handles string.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>str</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>Source content.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>For debug info.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>ext_src</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The source file&#39;s extension.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>data</code>
					
					<em>{ Any }</em>
				</b></p>
				<p><p>The data sent from the <code>render</code> function. Available only
when you call the <code>render</code> directly. Default is an empty object: <code>{ }</code>.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Any }</em>
				</b></p>
				<p><p>Promise or any thing that contains the compiled content.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L147">
				
				<b>file_handlers</b>
			</a>
		</h4>
		<p><p>You can access all the file_handlers here.
Manipulate them at runtime.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>example</u>:
					
					<em>{  }</em>
				</b></p>
				<p><pre><code class="lang-coffee"># We return js directly.
renderer.file_handlers[&#39;.js&#39;].compiler = (str) -&gt; str
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ Object }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L153">
				
				<b>cache_pool</b>
			</a>
		</h4>
		<p><p>The cache pool of the result of <code>file_handlers.compiler</code></p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Key is the file path.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L168">
				
				<b>static</b>
			</a>
		</h4>
		<p><p>Set a static directory.
Static folder to automatically serve coffeescript and stylus.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ String | Object }</em>
				</b></p>
				<p><p>If it&#39;s a string it represents the root_dir
of this static directory. Defaults:</p>
<pre><code class="lang-coffee">{
    root_dir: &#39;.&#39;
    index: process.env.NODE_ENV == &#39;development&#39; # Whether enable serve direcotry index.
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Middleware }</em>
				</b></p>
				<p><p>Experss.js middleware.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L234">
				
				<b>render</b>
			</a>
		</h4>
		<p><p>Render a file. It will auto detect the file extension and
choose the right compiler to handle the content.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The file path</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>data</code>
					
					<em>{ Any }</em>
				</b></p>
				<p><p>Extra data you want to send to the compiler.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>Contains the compiled content.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L247">
				
				<b>close</b>
			</a>
		</h4>
		<p><p>Release the resources.</p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L258">
				
				<b>e.compile_error</b>
			</a>
		</h4>
		<p></p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>compile_error</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p><p>The error file.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>err</code>
					
					<em>{ Error }</em>
				</b></p>
				<p><p>The error info.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L266">
				
				<b>e.watch_file</b>
			</a>
		</h4>
		<p></p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>watch_file</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p><p>The path of the file.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>curr</code>
					
					<em>{ fs.Stats }</em>
				</b></p>
				<p><p>Current state.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>prev</code>
					
					<em>{ fs.Stats }</em>
				</b></p>
				<p><p>Previous state.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L272">
				
				<b>e.file_deleted</b>
			</a>
		</h4>
		<p></p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>file_deleted</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p><p>The path of the file.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L278">
				
				<b>e.file_modified</b>
			</a>
		</h4>
		<p></p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>file_modified</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p><p>The path of the file.</p>
</p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>service</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L5">
				
				<b>Overview</b>
			</a>
		</h4>
		<p><p>It is just a Express.js wrap.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>extends</u>:
					
					<em>{ Express }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L24">
				
				<b>service</b>
			</a>
		</h4>
		<p><p>Create a Service instance.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    auto_log: process.env.NODE_ENV == &#39;development&#39;
    enable_remote_log: process.env.NODE_ENV == &#39;development&#39;
    enable_sse: process.env.NODE_ENV == &#39;development&#39;
    express: {}
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Service }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L47">
				
				<b>e.sse_connected</b>
			</a>
		</h4>
		<p><p>Triggered when a sse connection started.
The event name is a combination of sse_connected and req.path,
for example: &quot;sse_connected/test&quot;</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>sse_connected</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>The</code>
					
					<em>{ SSE_session }</em>
				</b></p>
				<p><p>session object of current connection.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L54">
				
				<b>e.sse_close</b>
			</a>
		</h4>
		<p><p>When a sse connection closed.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>event</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>sse_close</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ SSE_session }</em>
				</b></p>
				<p><p>The session object of current connection.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L109">
				
				<b>sse</b>
			</a>
		</h4>
		<p><p>A Server-Sent Event Manager.
The namespace of nobone sse is &#39;/nobone-sse&#39;,</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>example</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>You browser code should be something like this:</p>
<pre><code class="lang-coffee">es = new EventSource(&#39;/nobone-sse&#39;)
es.addEventListener(&#39;event_name&#39;, (e) -&gt;
    msg = JSON.parse(e.data)
    console.log(msg)
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ SSE }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L125">
				
				<b>session.emit</b>
			</a>
		</h4>
		<p><p>Emit message to client.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>event</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The event name.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ Object | String }</em>
				</b></p>
				<p><p>The message to send to the client.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L160">
				
				<b>sse.emit</b>
			</a>
		</h4>
		<p><p>Broadcast a event to clients.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>event</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The event name.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ Object | String }</em>
				</b></p>
				<p><p>The data you want to emit to session.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
					<em>{ String }</em>
				</b></p>
				<p><p>[path] The namespace of target sessions. If not set,
broadcast to all clients.</p>
</p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>kit</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L13">
				
				<b>kit</b>
			</a>
		</h4>
		<p><p>The <code>kit</code> lib of NoBone will load by default and is not optional.
All the async functions in <code>kit</code> return promise object.
Most time I use it to handle files and system staffs.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ Object }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L28">
				
				<b>denodeify_fs</b>
			</a>
		</h4>
		<p><p>Create promise wrap for all the functions that has
Sync version. For more info see node official doc of <code>fs</code>
There are some extra <code>fs</code> functions here,
see: <a href="https://github.com/jprichardson/node-fs-extra">https://github.com/jprichardson/node-fs-extra</a>
You can call <code>fs.readFile</code> like <code>kit.readFile</code>, it will
return a promise object.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>example</u>:
					
					<em>{  }</em>
				</b></p>
				<p><pre><code class="lang-coffee">kit.readFile(&#39;a.coffee&#39;).done (code) -&gt;
    kit.log code
</code></pre>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L50">
				
				<b>require</b>
			</a>
		</h4>
		<p><p>Much much faster than the native require of node, but
you should follow some rules to use it safely.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>module_name</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>Moudle path is not allowed!</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>done</code>
					
					<em>{ Function }</em>
				</b></p>
				<p><p>Run only the first time after the module loaded.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Module }</em>
				</b></p>
				<p><p>The module that you require.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L63">
				
				<b>path</b>
			</a>
		</h4>
		<p><p>Node native module</p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L68">
				
				<b>url</b>
			</a>
		</h4>
		<p><p>Node native module</p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L73">
				
				<b>jhash</b>
			</a>
		</h4>
		<p><p>See my jhash project: <a href="https://github.com/ysmood/jhash">https://github.com/ysmood/jhash</a></p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L80">
				
				<b>glob</b>
			</a>
		</h4>
		<p><p>See the <a href="https://github.com/isaacs/node-glob">https://github.com/isaacs/node-glob</a></p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>patterns</code>
					
					<em>{ String | Array }</em>
				</b></p>
				<p><p>Minimatch pattern.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>Contains the path list.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L100">
				
				<b>spawn</b>
			</a>
		</h4>
		<p><p>Safe version of <code>child_process.spawn</code> to run a process on Windows or Linux.
It will automatically add <code>node_modules/.bin</code> to the <code>PATH</code> environment variable.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>cmd</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>Path of an executable program.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>args</code>
					
					<em>{ Array }</em>
				</b></p>
				<p><p>CLI arguments.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Process options. Same with the Node.js official doc.
Default will inherit the parent&#39;s stdio.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>The <code>promise.process</code> is the child process object.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L138">
				
				<b>extend_env</b>
			</a>
		</h4>
		<p><p>Automatically add <code>node_modules/.bin</code> to the <code>PATH</code> environment variable.</p>
</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L160">
				
				<b>monitor_app</b>
			</a>
		</h4>
		<p><p>Monitor an application and automatically restart it when file changed.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    bin: &#39;node&#39;
    args: [&#39;app.js&#39;]
    watch_list: [&#39;app.js&#39;]
    mode: &#39;development&#39;
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Process }</em>
				</b></p>
				<p><p>The child process.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L219">
				
				<b>watch_files</b>
			</a>
		</h4>
		<p><p>Watch files, when file changes, the handler will be invoked.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>patterns</code>
					
					<em>{ Array }</em>
				</b></p>
				<p><p>String array with minimatch syntax.
Such as <code>[&#39;\*.css&#39;, &#39;lib/\*\*.js&#39;]</code>.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>handler</code>
					
					<em>{ Function }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L231">
				
				<b>env_mode</b>
			</a>
		</h4>
		<p><p>A shortcut to set process option with specific mode,
and keep the current env variables.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>mode</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>&#39;development&#39;, &#39;production&#39;, etc.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Object }</em>
				</b></p>
				<p><p><code>process.env</code> object.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L246">
				
				<b>inspect</b>
			</a>
		</h4>
		<p><p>For debugging use. Dump a colorful object.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>obj</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Your target object.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Options. Default:
{ colors: true, depth: 5 }</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ String }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L265">
				
				<b>log</b>
			</a>
		</h4>
		<p><p>A better log for debugging, it uses the <code>kit.inspect</code> to log.</p>
<p>You can use terminal command like <code>log_reg=&#39;pattern&#39; node app.js</code> to
filter the log info.</p>
<p>You can use <code>log_trace=&#39;on&#39; node app.js</code> to force each log end with a
stack trace.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ Any }</em>
				</b></p>
				<p><p>Your log message.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>action</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>&#39;log&#39;, &#39;error&#39;, &#39;warn&#39;.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Default is same with <code>kit.inspect</code></p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L300">
				
				<b>err</b>
			</a>
		</h4>
		<p><p>A log error shortcut for <code>kit.log</code></p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ Any }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L314">
				
				<b>daemonize</b>
			</a>
		</h4>
		<p><p>Daemonize a program.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:
{
    bin: &#39;node&#39;
    args: [&#39;app.js&#39;]
    stdout: &#39;stdout.log&#39;
    stderr: &#39;stderr.log&#39;
}</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Porcess }</em>
				</b></p>
				<p><p>The daemonized process.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L339">
				
				<b>prompt_get</b>
			</a>
		</h4>
		<p><p>Block terminal and wait for user inputs. Useful when you need
user interaction.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>See the <a href="https://github.com/flatiron/prompt">https://github.com/flatiron/prompt</a></p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>Contains the results of prompt.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L360">
				
				<b>async_limit</b>
			</a>
		</h4>
		<p><p>An throttle version of <code>Q.all</code>, it runs all the tasks under
a concurrent limitation.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>list</code>
					
					<em>{ Array }</em>
				</b></p>
				<p><p>A list of functions. Each will return a promise.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>limit</code>
					
					<em>{ Int }</em>
				</b></p>
				<p><p>The max task to run at the same time.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L413">
				
				<b>parse_comment</b>
			</a>
		</h4>
		<p><p>A comments parser for coffee-script. Used to generate documentation automatically.
It will traverse through all the comments.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>module_name</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The name of the module it belongs to.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>code</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>Coffee source code.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>The path of the source code.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Parser options:</p>
<pre><code class="lang-coffee">{
    comment_reg: RegExp
    split_reg: RegExp
    tag_name_reg: RegExp
    type_reg: RegExp
    name_reg: RegExp
    description_reg: RegExp
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Array }</em>
				</b></p>
				<p><p>The parsed comments. Each item is something like:</p>
<pre><code class="lang-coffee">{
    module: &#39;nobone&#39;
    name: &#39;parse_comment&#39;
    description: &#39;A comments parser for coffee-script.&#39;
    tags: [
        {
            tag_name: &#39;param&#39;
            type: &#39;string&#39;
            name: &#39;code&#39;
            description: &#39;The name of the module it belongs to.&#39;
            path: &#39;http://the_path_of_source_code&#39;
            index: 256 # The target char index in the file.
            line: 32 # The line number of the target in the file.
        }
    ]
}
</code></pre>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L496">
				
				<b>generate_bone</b>
			</a>
		</h4>
		<p><p>A scaffolding helper to generate template project.
The <code>lib/cli.coffee</code> used it as an example.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    prompt: null
    src_dir: null
    pattern: &#39;**&#39;
    dest_dir: null
    compile: (str, data, path) -&gt;
        compile str
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L533">
				
				<b>is_file_exists</b>
			</a>
		</h4>
		<p><p>Check if a file path exists.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ String }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Boolean }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L548">
				
				<b>is_dir_exists</b>
			</a>
		</h4>
		<p><p>Check if a directory path exists.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ String }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Boolean }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>nobone</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L18">
				
				<b>nobone</b>
			</a>
		</h4>
		<p><p>Main constructor.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    db: null
    proxy: null
    service: {}
    renderer: {}
}
</code></pre>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Object }</em>
				</b></p>
				<p><p>A nobone instance.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L46">
				
				<b>nb.close</b>
			</a>
		</h4>
		<p><p>Release the resources.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L68">
				
				<b>module_defaults</b>
			</a>
		</h4>
		<p><p>Help you to get the default options of moduels.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>static</u>:
					
					<em>{  }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>name</code>
					
					<em>{ String }</em>
				</b></p>
				<p><p>Module name, if not set, return all modules&#39; defaults.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>A promise object which will produce the defaults.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L89">
				
				<b>client</b>
			</a>
		</h4>
		<p><p>The NoBone client helper.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>static</u>:
					
					<em>{  }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>auto</code>
					
					<em>{ Boolean }</em>
				</b></p>
				<p><p>If true, and not on development mode
return an empty string.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ String }</em>
				</b></p>
				<p><p>The html of client helper.</p>
</p>
			</li>

			
		</ul>
	</li>

	
</ul>

<hr>




## Changelog

See the [doc/changelog.md](https://github.com/ysmood/nobone/blob/master/doc/changelog.md) file.


## Unit Test

	npm test


## Benchmark


<p>Memory cache is faster than direct file streaming even on SSD machine.</p>
<pre><code>* memory x 1,167 ops/sec ±4.11% (68 runs sampled)
* stream x   759 ops/sec ±2.77% (79 runs sampled)
</code></pre>

<p>As we can see, jhash is about 1.5x faster than crc32.
And the results collision test are nearly the same.</p>
<pre><code>Performance Test
crc buffer   x 5,903 ops/sec ±0.52% (100 runs sampled)
crc str      x 54,045 ops/sec ±6.67% (83 runs sampled)
jhash buffer x 9,756 ops/sec ±0.67% (101 runs sampled)
jhash str    x 72,056 ops/sec ±0.36% (94 runs sampled)

Collision Test
***** jhash *****
  5 samples: 3481292839,1601668515,957061576,1031084327,1000054056
      time: 10.001s
collisions: 0.0018788163457017504% (4/212900)
***** crc32 *****
  5 samples: 3494480258,2736329845,2815219153,3510180228,2016919691
      time: 10.003s
collisions: 0.0027945971122544933% (6/214700)
</code></pre>



## Road Map

Decouple libs.

Better test coverage.


## Lisence

### BSD

May 2014, Yad Smood
