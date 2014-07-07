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
<%- usage %>
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
					<u><%- tag.tag_name %></u>:
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


## Changelog

See the [doc/changelog.md](https://github.com/ysmood/nobone/blob/master/doc/changelog.md) file.


## Unit Test

	npm test


## Benchmark

<%- benchmark[0].description %>


## Road Map

Decouple libs.

Better test coverage.


## Lisence

### BSD

May 2014, Yad Smood
