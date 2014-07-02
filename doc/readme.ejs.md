## Overview

A server library which will ease you development life.

Now NoBone is based on express.js and some other useful libraries.

[![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone)

## Install

    npm install nobone


## Quick Start

```coffeescript
<%= usage %>
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


## Modules

NoBone has four main modules, they are all optional.

### db

See my JDB project: https://github.com/ysmood/jdb

### proxy

For test, page injection development.

### renderer

A abstract renderer for any string resources, such as template, source code, etc.
It automatically uses high performance memory cache. You can run the benchmark to see the what differences it makes. Even for huge project its memory usage is negligible.

### service

It is just a Express.js wrap with build in Socket.io (optional).

### kit

The `kit` lib of NoBone will load by default and is not optinal.
All the async functions in `kit` return promise object.
Most time I use it to handle files and system staffs.


## Road Map

API doc.

Better test coverage.


## BSD

May 2014, Yad Smood
