## Overview

A server library which will ease you development life.

Now NoBone is based on express.js and some other useful libraries.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)

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


<% _.each(mods, function(mod, mod_name) { %>

<h3><%- mod_name %></h3>
<ul>
	<% _.each(mod, function(el) { %>

	<hr>

	<li>
		<h4>
			<a href="https://github.com/ysmood/nobone/blob/master/<%= el.path %>#L<%= el.line %>">
				<%
					var name = el.name.replace('self.', '');
					if (_.find(el.tags, function (el) {
						return el.tag == 'return';
					}))
						name += '()'
				%>
				<b><%= name %></b>
			</a>
		</h4>
		<p><%- el.description %></p>

		<ul>
			<% _.each(el.tags, function(tag) { %>

			<li>
				<p><b>
					<u><%- tag.tag %></u>:
					<% if (tag.name) { %>
						<code><%- tag.name %></code>
					<% } %>
					<em>{ <%- tag.type %> }</em>
				</b></p>
				<p><%- tag.description %></p>
			</li>

			<% }); %>
		</ul>
	</li>

	<% }); %>
</ul>

<hr>

<% }); %>


## Unit Test

	npm test


# Benchmark

<%- benchmark[0].description %>


## Road Map

Decouple libs.

Better test coverage.


# Lisence

## BSD

May 2014, Yad Smood
