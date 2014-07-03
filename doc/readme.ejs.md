## Overview

A server library which will ease you development life.

Now NoBone is based on express.js and some other useful libraries.

[![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone)

## Install

    npm install nobone


## Quick Start

```coffeescript
<%- usage %>
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


<% _.each(mods, function(mod, name) { %>

<h3><%- name %></h3>
<ul>
	<% _.each(mod, function(el) { %>

	<li>
		<h4>
			<b><%- el.name %></b>
		</h4>
		<p><%- el.description %></p>

		<ul>
			<% _.each(el.tags, function(tag) { %>

			<li>
				<p><b>@<%- tag.tag %>: <%- tag.name %> { <%- tag.type %> }</b></p>
				<pre><%- tag.description %></pre>
			</li>

			<% }); %>
		</ul>
	</li>

	<% }); %>
</ul>


<% }); %>


## Unit Test

	npm test


## Road Map

API doc.

Better test coverage.


## BSD

May 2014, Yad Smood
