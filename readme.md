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


## Modules API

NoBone has four main modules, they are all optional.




<h3>db</h3>
<ul>
	

	<li>
		<h4>
			<b>module.exports</b>
		</h4>
		<p>See my JDB project: https://github.com/ysmood/jdb</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Defaults:
{
	promise: true
	db_path: './nobone.db'
}</pre>
			</li>

			

			<li>
				<p><b>@return:  { jdb }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	
</ul>




<h3>proxy</h3>
<ul>
	

	<li>
		<h4>
			<b>module.exports</b>
		</h4>
		<p>For test, page injection development.</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Defaults: {}</pre>
			</li>

			

			<li>
				<p><b>@return:  { proxy }</b></p>
				<pre>See https://github.com/nodejitsu/node-http-proxy
I extend only on function to it `url`. Use it to proxy one url
to another.</pre>
			</li>

			
		</ul>
	</li>

	
</ul>




<h3>renderer</h3>
<ul>
	

	<li>
		<h4>
			<b>module.exports</b>
		</h4>
		<p>A abstract renderer for any string resources, such as template, source code, etc.
It automatically uses high performance memory cache.
You can run the benchmark to see the what differences it makes.
Even for huge project its memory usage is negligible.</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Defaults:
{
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
 *
				(data = {}) ->
					_.defaults data, { _ }
					tpl data
		}
	}
}</pre>
			</li>

			

			<li>
				<p><b>@return:  { renderer }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>self.static</b>
		</h4>
		<p>Set a static directory.
Static folder to automatically serve coffeescript and stylus.</p>

		<ul>
			

			<li>
				<p><b>@param: Defaults { object }</b></p>
				<pre>: { root_dir: '.' }</pre>
			</li>

			

			<li>
				<p><b>@return:  { middleware }</b></p>
				<pre>Experss.js middleware.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>self.render</b>
		</h4>
		<p>Render a file. It will auto detect the file extension and
choose the right compiler to handle the code.</p>

		<ul>
			

			<li>
				<p><b>@param: path { string }</b></p>
				<pre>The file path</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre>Contains the compiled code.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>self.auto_reload</b>
		</h4>
		<p>The browser javascript to support the auto page reload.
You can use the socket.io event to custom you own.</p>

		<ul>
			

			<li>
				<p><b>@return:  { string }</b></p>
				<pre>Returns html.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>self.close</b>
		</h4>
		<p>Release the resources.</p>

		<ul>
			
		</ul>
	</li>

	
</ul>




<h3>service</h3>
<ul>
	

	<li>
		<h4>
			<b>module.exports</b>
		</h4>
		<p>It is just a Express.js wrap with build in Socket.io (optional).</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Defaults:
{
	enable_socketio: process.env.NODE_ENV == 'development'
	express: {}
}</pre>
			</li>

			

			<li>
				<p><b>@return:  { service }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	
</ul>




<h3>kit</h3>
<ul>
	

	<li>
		<h4>
			<b>kit</b>
		</h4>
		<p>The `kit` lib of NoBone will load by default and is not optinal.
All the async functions in `kit` return promise object.
Most time I use it to handle files and system staffs.</p>

		<ul>
			

			<li>
				<p><b>@type:  { object }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>denodeify_fs</b>
		</h4>
		<p>Create promise wrap for all the functions that has
Sync version. For more info see node official doc of `fs`
There are some extra `fs` functions here,
see: https://github.com/jprichardson/node-fs-extra
You can call `fs.readFile` like `kit.readFile`, it will
return a promise object.</p>

		<ul>
			

			<li>
				<p><b>@example:  {  }</b></p>
				<pre>kit.readFile('a.coffee').done (code) ->
	kit.log code</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>path</b>
		</h4>
		<p>Node native module</p>

		<ul>
			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>url</b>
		</h4>
		<p>Node native module</p>

		<ul>
			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>glob</b>
		</h4>
		<p>See the https://github.com/isaacs/node-glob</p>

		<ul>
			

			<li>
				<p><b>@param: pattern { string }</b></p>
				<pre>Minimatch pattern.</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>spawn</b>
		</h4>
		<p>Safe version of `child_process.spawn` a process on Windows or Linux.</p>

		<ul>
			

			<li>
				<p><b>@param: cmd { string }</b></p>
				<pre>Path of an executable program.</pre>
			</li>

			

			<li>
				<p><b>@param: args { array }</b></p>
				<pre>CLI arguments.</pre>
			</li>

			

			<li>
				<p><b>@param: options { object }</b></p>
				<pre>Process options.
Default will inherit the parent's stdio.</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre>The `promise.process` is the child process object.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>monitor_app</b>
		</h4>
		<p>Monitor an application and automatically restart it when file changed.</p>

		<ul>
			

			<li>
				<p><b>@param: options { object }</b></p>
				<pre>Defaults:
{
    bin: 'node'
    args: ['app.js']
    watch_list: ['app.js']
    mode: 'development'
}</pre>
			</li>

			

			<li>
				<p><b>@return:  { process }</b></p>
				<pre>The child process.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>watch_files</b>
		</h4>
		<p>Watch files, when file changes, the handler will be invoked.</p>

		<ul>
			

			<li>
				<p><b>@param: patterns { array }</b></p>
				<pre>String array with minimatch syntax.
/**.js', '*.css']</pre>
			</li>

			

			<li>
				<p><b>@param: handler { function }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>env_mode</b>
		</h4>
		<p>A shortcut to set process option with specific mode,
and keep the current env varialbes.</p>

		<ul>
			

			<li>
				<p><b>@param: mode { string }</b></p>
				<pre>'development', 'production', etc.</pre>
			</li>

			

			<li>
				<p><b>@return:  { object }</b></p>
				<pre>`process.env` object.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>inspect</b>
		</h4>
		<p>For debugging use. Dump a colorful object.</p>

		<ul>
			

			<li>
				<p><b>@param: obj { object }</b></p>
				<pre>Your target object.</pre>
			</li>

			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Options. Default:
{ colors: true, depth: 5 }</pre>
			</li>

			

			<li>
				<p><b>@return:  { string }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>log</b>
		</h4>
		<p>A better log for debugging, it uses the `kit.inspect` to log.</p>

		<ul>
			

			<li>
				<p><b>@param: msg { any }</b></p>
				<pre>Your log message.</pre>
			</li>

			

			<li>
				<p><b>@param: action { string }</b></p>
				<pre>'log', 'error', 'warn'.</pre>
			</li>

			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Default is same with `kit.inspect`</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>prompt_get</b>
		</h4>
		<p>Block terminal and wait for user inputs.</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>See the https://github.com/flatiron/prompt</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre>Contains the results of prompt.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>async_limit</b>
		</h4>
		<p>An throttle version of `Q.all`, it runs all the tasks under
a limitation.</p>

		<ul>
			

			<li>
				<p><b>@param: list { array }</b></p>
				<pre>A list of functions. Each will return a promise.</pre>
			</li>

			

			<li>
				<p><b>@param: limit { int }</b></p>
				<pre>The max task to run at the same time.</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>parse_comment</b>
		</h4>
		<p>A comments parser for coffee-script.
Used to generate documantation automatically.</p>

		<ul>
			

			<li>
				<p><b>@param: module_name { string }</b></p>
				<pre>The name of the module it belongs to.</pre>
			</li>

			

			<li>
				<p><b>@param: code { string }</b></p>
				<pre>Coffee source code.</pre>
			</li>

			

			<li>
				<p><b>@return:  { array }</b></p>
				<pre>The parsed comments. Something like:
{
		module: 'nobone'
		name: 'parse_comment'
		description: A comments parser for coffee-script.
		tags: [
			{
				tag: 'param'
				type: 'string'
				name: 'module_name'
				description: 'The name of the module it belongs to.'
			}
		]
}</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>generate_bone</b>
		</h4>
		<p>A scaffolding helper to generate template project.
The `lib/cli.coffee` used it as an example.</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre>Defaults:
{
		prompt: null
		src_dir: null
		pattern: '**'
		dest_dir: null
		compile: (str, data, path) ->
			ejs = kit._require 'ejs'
			data.filename = path
			ejs.render str, data
}</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre></pre>
			</li>

			
		</ul>
	</li>

	
</ul>




<h3>nobone</h3>
<ul>
	

	<li>
		<h4>
			<b>create</b>
		</h4>
		<p>Main constructor.</p>

		<ul>
			

			<li>
				<p><b>@param: opts { object }</b></p>
				<pre></pre>
			</li>

			

			<li>
				<p><b>@return:  { object }</b></p>
				<pre>A nobone instance.</pre>
			</li>

			
		</ul>
	</li>

	

	<li>
		<h4>
			<b>module_defaults</b>
		</h4>
		<p>Help you to get the default options of moduels.</p>

		<ul>
			

			<li>
				<p><b>@param: name { string }</b></p>
				<pre>Module name, if not set, return all modules' defaults.</pre>
			</li>

			

			<li>
				<p><b>@return:  { promise }</b></p>
				<pre>A promise object with defaults.</pre>
			</li>

			
		</ul>
	</li>

	
</ul>





## Unit Test

	npm test


## Road Map

API doc.

Better test coverage.


## BSD

May 2014, Yad Smood
