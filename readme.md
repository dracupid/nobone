## Overview

A server library knows what developer really needs.

Now NoBone is based on express.js and some other useful libraries.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)


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
# By default it load two module: service, renderer
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
	# You can also render coffee, stylus, markdown, or define custom handlers.
	nb.renderer.render('bone/index.ejs')
	.done (tpl_func) ->
		res.send tpl_func({ body: nb.renderer.auto_reload() })

# Launch socket.io and express.js
s = nb.service.listen port

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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/db.coffee#L13">
				
				<b>db()</b>
			</a>
		</h4>
		<p><p>See my JDB project: <a href="https://github.com/ysmood/jdb">https://github.com/ysmood/jdb</a></p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L14">
				
				<b>proxy()</b>
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
					
					<em>{  }</em>
				</b></p>
				<p><p>{http-proxy.ProxyServer}</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults: <code>{}</code></p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L26">
				
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

			
		</ul>
	</li>

	
</ul>

<hr>



<h3>renderer</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L42">
				
				<b>renderer()</b>
			</a>
		</h4>
		<p><p>A abstract renderer for any string resources, such as template, source code, etc.
It automatically uses high performance memory cache.
You can run the benchmark to see the what differences it makes.
Even for huge project its memory usage is negligible.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>extends</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>{events.EventEmitter}</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    enable_watcher: process.env.NODE_ENV == &#39;development&#39;
    auto_log: process.env.NODE_ENV == &#39;development&#39;
    code_handlers: {
        &#39;.html&#39;: {
            default: true
            ext_src: &#39;.ejs&#39;
            type: &#39;html&#39;
            compiler: (str, path) -&gt; ...
        }
        &#39;.js&#39;: {
            ext_src: &#39;.coffee&#39;
            compiler: (str, path) -&gt; ...
        }
        &#39;.css&#39;: {
            ext_src: &#39;.styl&#39;
            compiler: (str, path) -&gt; ...
        }
        &#39;.md&#39;: {
            ext_src: &#39;.md&#39;
            type: &#39;html&#39;
            compiler: (str, path) -&gt; ...
        }
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L59">
				
				<b>compiler()</b>
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
				<p><p>Source code.</p>
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
					<u>return</u>:
					
					<em>{ Any }</em>
				</b></p>
				<p><p>Promise or any thing that contains the compiled code.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L111">
				
				<b>code_handlers</b>
			</a>
		</h4>
		<p><p>You can access all the code_handlers here.
Manipulate them at runtime.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>example</u>:
					
					<em>{  }</em>
				</b></p>
				<p><pre><code class="lang-coffee"># We return js directly.
renderer.code_handlers[&#39;.js&#39;].compiler = (str) -&gt; str
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L117">
				
				<b>cache_pool</b>
			</a>
		</h4>
		<p><p>The cache pool of the result of <code>code_handlers.compiler</code></p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L126">
				
				<b>static()</b>
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
of this static directory. Defaults: <code>{ root_dir: &#39;.&#39; }</code></p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L178">
				
				<b>render()</b>
			</a>
		</h4>
		<p><p>Render a file. It will auto detect the file extension and
choose the right compiler to handle the code.</p>
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
					<u>return</u>:
					
					<em>{ Promise }</em>
				</b></p>
				<p><p>Contains the compiled code.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L191">
				
				<b>auto_reload()</b>
			</a>
		</h4>
		<p><p>The browser javascript to support the auto page reload.
You can use the socket.io event to custom you own.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ String }</em>
				</b></p>
				<p><p>Returns html.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L197">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L209">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L217">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L223">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L229">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L16">
				
				<b>service()</b>
			</a>
		</h4>
		<p><p>It is just a Express.js wrap with build in Socket.io (optional).</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>extends</u>:
					
					<em>{  }</em>
				</b></p>
				<p><p>{Express}</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ Object }</em>
				</b></p>
				<p><p>Defaults:</p>
<pre><code class="lang-coffee">{
    enable_socketio: process.env.NODE_ENV == &#39;development&#39;
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
				
				<b>require()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L75">
				
				<b>glob()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L94">
				
				<b>spawn()</b>
			</a>
		</h4>
		<p><p>Safe version of <code>child_process.spawn</code> to run a process on Windows or Linux.</p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L136">
				
				<b>monitor_app()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L195">
				
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
Such as <code>[&#39;./* /**.js&#39;, &#39;*.css&#39;]</code></p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L207">
				
				<b>env_mode()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L222">
				
				<b>inspect()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L239">
				
				<b>log</b>
			</a>
		</h4>
		<p><p>A better log for debugging, it uses the <code>kit.inspect</code> to log.
You can use terminal command like <code>log_reg=&#39;pattern&#39; node app.js</code> to
filter the log info.
You can use <code>log_trace=&#39;on&#39; node app.js</code> to force each log end with a
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L274">
				
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L283">
				
				<b>prompt_get()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L304">
				
				<b>async_limit()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L357">
				
				<b>parse_comment()</b>
			</a>
		</h4>
		<p><p>A comments parser for coffee-script.
Used to generate documentation automatically.</p>
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
					
						<code>sting</code>
					
					<em>{ Path }</em>
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
    reg: RegExp
    split_reg: RegExp
    tag_name_reg: RegExp
    tag_2_reg: RegExp
    tag_3_reg: RegExp
    tag_4_reg: RegExp
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
    description: A comments parser for coffee-script.
    tags: [
        {
            tag: &#39;param&#39;
            type: &#39;string&#39;
            name: &#39;module_name&#39;
            description: &#39;The name of the module it belongs to.&#39;
            path: &#39;http://the_path_of_source_code&#39;
            index: 256 # The target char index in the file.
            line: 29 # The line number of the target in the file.
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L442">
				
				<b>generate_bone()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L479">
				
				<b>is_file_exists()</b>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L494">
				
				<b>is_dir_exists()</b>
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
				
				<b>nobone()</b>
			</a>
		</h4>
		<p><p>Main constructor.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
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
					
					<em>{ object }</em>
				</b></p>
				<p><p>A nobone instance.</p>
</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L42">
				
				<b>nb.close()</b>
			</a>
		</h4>
		<p><p>Release the resources.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L63">
				
				<b>module_defaults()</b>
			</a>
		</h4>
		<p><p>Help you to get the default options of moduels.</p>
</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>name</code>
					
					<em>{ string }</em>
				</b></p>
				<p><p>Module name, if not set, return all modules&#39; defaults.</p>
</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p><p>A promise object which will produce the defaults.</p>
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
<pre>
* memory x 1,167 ops/sec ±4.11% (68 runs sampled)
* stream x   759 ops/sec ±2.77% (79 runs sampled)
</pre>


## Road Map

Decouple libs.

Better test coverage.


## Lisence

### BSD

May 2014, Yad Smood
