## Overview

A server library which will ease you life.

Now NoBone is based on express.js and some other useful libraries.

[![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone)

NoBone has four main modules, they are all optional.

* db
* proxy
* renderer
* service

The `kit` lib of NoBone will load is not optinal, and will load automatically.
All the async functions in `kit` return promise object.
Most time I use it to handle files and system staffs.


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



## BSD

May 2014, Yad Smood
