## Overview

A server library which will ease you development life.

Now NoBone is based on express.js and some other useful libraries.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)


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
nobone.module_defaults().done (list) ->
	nb.kit.log 'module_defaults'
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

# Edit the 'tpl/client/index.ejs' file, the page should auto reload.
nb.renderer.on 'watch_file', (path) ->
	nb.kit.log 'Watch: '.cyan + path
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/db.coffee#L12">
				
				<b>module.exports()</b>
			</a>
		</h4>
		<p>See my JDB project: https://github.com/ysmood/jdb</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
<pre>{
	promise: true
	db_path: './nobone.db'
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ jdb }</em>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/proxy.coffee#L13">
				
				<b>module.exports()</b>
			</a>
		</h4>
		<p>For test, page injection development.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults: <code>{}</code></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ proxy }</em>
				</b></p>
				<p>See https://github.com/nodejitsu/node-http-proxy
I extend only on function to it <code>url</code>. Use it to proxy one url
to another.</p>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L45">
				
				<b>module.exports()</b>
			</a>
		</h4>
		<p>A abstract renderer for any string resources, such as template, source code, etc.
It automatically uses high performance memory cache.
You can run the benchmark to see the what differences it makes.
Even for huge project its memory usage is negligible.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
<pre>{
	enable_watcher: process.env.NODE_ENV == 'development'
	code_handlers: {
		'.js': {
			ext_src: '.coffee'
			compiler: (str) ->
				coffee = require 'coffee-script'
				coffee.compile(str, { bare: true })
		}
		'.css': {
			ext_src: '.styl'
			compiler: (str, path) ->
				stylus = require 'stylus'
				stylus_render = Q.denodeify stylus.render
				stylus_render(str, { filename: path })
		}
		'.ejs': {
			default: true    # Whether it is a default handler
			ext_src: '.ejs'
			type: 'html'
			compiler: (str, path) ->
				ejs = require 'ejs'
				tpl = ejs.compile str, { filename: path }

				(data = {}) ->
					_.defaults data, { _ }
					tpl data
		}
	}
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ renderer }</em>
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
		<p>The compiler should fulfil two interface.
It should return a promise object. Only handles string.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>str</code>
					
					<em>{ string }</em>
				</b></p>
				<p>Source code.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p>For debug info.</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p>Contains the compiled code.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L104">
				
				<b>static()</b>
			</a>
		</h4>
		<p>Set a static directory.
Static folder to automatically serve coffeescript and stylus.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults: <code>{ root_dir: '.' }</code></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ middleware }</em>
				</b></p>
				<p>Experss.js middleware.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L150">
				
				<b>render()</b>
			</a>
		</h4>
		<p>Render a file. It will auto detect the file extension and
choose the right compiler to handle the code.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>path</code>
					
					<em>{ string }</em>
				</b></p>
				<p>The file path</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p>Contains the compiled code.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L159">
				
				<b>auto_reload()</b>
			</a>
		</h4>
		<p>The browser javascript to support the auto page reload.
You can use the socket.io event to custom you own.</p>

		<ul>
			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ string }</em>
				</b></p>
				<p>Returns html.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/renderer.coffee#L181">
				
				<b>close</b>
			</a>
		</h4>
		<p>Release the resources.</p>

		<ul>
			
		</ul>
	</li>

	
</ul>

<hr>



<h3>service</h3>
<ul>
	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/modules/service.coffee#L14">
				
				<b>module.exports()</b>
			</a>
		</h4>
		<p>It is just a Express.js wrap with build in Socket.io (optional).</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
<pre>{
	enable_socketio: process.env.NODE_ENV == 'development'
	express: {}
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ service }</em>
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
		<p>The <code>kit</code> lib of NoBone will load by default and is not optional.
All the async functions in <code>kit</code> return promise object.
Most time I use it to handle files and system staffs.</p>

		<ul>
			

			<li>
				<p><b>
					<u>type</u>:
					
					<em>{ object }</em>
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
		<p>Create promise wrap for all the functions that has
Sync version. For more info see node official doc of <code>fs</code>
There are some extra <code>fs</code> functions here,
see: https://github.com/jprichardson/node-fs-extra
You can call <code>fs.readFile</code> like <code>kit.readFile</code>, it will
return a promise object.</p>

		<ul>
			

			<li>
				<p><b>
					<u>example</u>:
					
					<em>{  }</em>
				</b></p>
				<p><pre>
kit.readFile('a.coffee').done (code) ->
	kit.log code
</pre></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L57">
				
				<b>path</b>
			</a>
		</h4>
		<p>Node native module</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L62">
				
				<b>url</b>
			</a>
		</h4>
		<p>Node native module</p>

		<ul>
			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L69">
				
				<b>glob()</b>
			</a>
		</h4>
		<p>See the https://github.com/isaacs/node-glob</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>pattern</code>
					
					<em>{ string }</em>
				</b></p>
				<p>Minimatch pattern.</p>
			</li>

			

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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L79">
				
				<b>spawn()</b>
			</a>
		</h4>
		<p>Safe version of <code>child_process.spawn</code> a process on Windows or Linux.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>cmd</code>
					
					<em>{ string }</em>
				</b></p>
				<p>Path of an executable program.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>args</code>
					
					<em>{ array }</em>
				</b></p>
				<p>CLI arguments.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>options</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Process options.
Default will inherit the parent's stdio.</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p>The <code>promise.process</code> is the child process object.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L120">
				
				<b>monitor_app()</b>
			</a>
		</h4>
		<p>Monitor an application and automatically restart it when file changed.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>options</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
<pre>{
	bin: 'node'
	args: ['app.js']
	watch_list: ['app.js']
	mode: 'development'
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ process }</em>
				</b></p>
				<p>The child process.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L179">
				
				<b>watch_files</b>
			</a>
		</h4>
		<p>Watch files, when file changes, the handler will be invoked.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>patterns</code>
					
					<em>{ array }</em>
				</b></p>
				<p>String array with minimatch syntax.
Such as <code>['./* /**.js', '*.css']</code></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>handler</code>
					
					<em>{ function }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L191">
				
				<b>env_mode()</b>
			</a>
		</h4>
		<p>A shortcut to set process option with specific mode,
and keep the current env variables.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>mode</code>
					
					<em>{ string }</em>
				</b></p>
				<p>'development', 'production', etc.</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ object }</em>
				</b></p>
				<p><code>process.env</code> object.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L205">
				
				<b>inspect()</b>
			</a>
		</h4>
		<p>For debugging use. Dump a colorful object.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>obj</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Your target object.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Options. Default:
{ colors: true, depth: 5 }</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ string }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L222">
				
				<b>log</b>
			</a>
		</h4>
		<p>A better log for debugging, it uses the <code>kit.inspect</code> to log.
You can use terminal command like <code>log_reg='pattern' node app.js</code> to
filter the log info.
You can use <code>log_trace='on' node app.js</code> to force each log end with a
stack trace.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ any }</em>
				</b></p>
				<p>Your log message.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>action</code>
					
					<em>{ string }</em>
				</b></p>
				<p>'log', 'error', 'warn'.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Default is same with <code>kit.inspect</code></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L257">
				
				<b>err</b>
			</a>
		</h4>
		<p>A log error shortcut for <code>kit.log</code></p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>msg</code>
					
					<em>{ any }</em>
				</b></p>
				<p></p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L266">
				
				<b>prompt_get()</b>
			</a>
		</h4>
		<p>Block terminal and wait for user inputs. Useful when you need
user interaction.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>See the https://github.com/flatiron/prompt</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p>Contains the results of prompt.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L287">
				
				<b>async_limit()</b>
			</a>
		</h4>
		<p>An throttle version of <code>Q.all</code>, it runs all the tasks under
a concurrent limitation.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>list</code>
					
					<em>{ array }</em>
				</b></p>
				<p>A list of functions. Each will return a promise.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>limit</code>
					
					<em>{ int }</em>
				</b></p>
				<p>The max task to run at the same time.</p>
			</li>

			

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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L339">
				
				<b>parse_comment()</b>
			</a>
		</h4>
		<p>A comments parser for coffee-script.
Used to generate documentation automatically.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>module_name</code>
					
					<em>{ string }</em>
				</b></p>
				<p>The name of the module it belongs to.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>code</code>
					
					<em>{ string }</em>
				</b></p>
				<p>Coffee source code.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>sting</code>
					
					<em>{ path }</em>
				</b></p>
				<p>The path of the source code.</p>
			</li>

			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Parser options:
<pre>{
	reg: RegExp
	split_reg: RegExp
	tag_name_reg: RegExp
	tag_2_reg: RegExp
	tag_3_reg: RegExp
	tag_4_reg: RegExp
	code_reg: RegExp
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ array }</em>
				</b></p>
				<p>The parsed comments. Each item is something like:
<pre>{
	module: 'nobone'
	name: 'parse_comment'
	description: A comments parser for coffee-script.
	tags: [
		{
			tag: 'param'
			type: 'string'
			name: 'module_name'
			description: 'The name of the module it belongs to.'
			path: 'http://the_path_of_source_code'
			index: 256 # The target char index in the file.
			line: 29 # The line number of the target in the file.
		}
	]
}</pre></p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L426">
				
				<b>generate_bone()</b>
			</a>
		</h4>
		<p>A scaffolding helper to generate template project.
The <code>lib/cli.coffee</code> used it as an example.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
<pre>{
	prompt: null
	src_dir: null
	pattern: '**'
	dest_dir: null
	compile: (str, data, path) ->
		ejs = kit._require 'ejs'
		data.filename = path
		ejs.render str, data
}</pre></p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L20">
				
				<b>create()</b>
			</a>
		</h4>
		<p>Main constructor.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>opts</code>
					
					<em>{ object }</em>
				</b></p>
				<p>Defaults:
{
	db: null
	proxy: null
	service: {}
	renderer: {}
}</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ object }</em>
				</b></p>
				<p>A nobone instance.</p>
			</li>

			
		</ul>
	</li>

	

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L44">
				
				<b>nb.close()</b>
			</a>
		</h4>
		<p>Release the resources.</p>

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
			<a href="https://github.com/ysmood/nobone/blob/master/lib/nobone.coffee#L61">
				
				<b>module_defaults()</b>
			</a>
		</h4>
		<p>Help you to get the default options of moduels.</p>

		<ul>
			

			<li>
				<p><b>
					<u>param</u>:
					
						<code>name</code>
					
					<em>{ string }</em>
				</b></p>
				<p>Module name, if not set, return all modules' defaults.</p>
			</li>

			

			<li>
				<p><b>
					<u>return</u>:
					
					<em>{ promise }</em>
				</b></p>
				<p>A promise object which will produce the defaults.</p>
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

Memory cache is faster than direct file streaming even on SSD machine.
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
