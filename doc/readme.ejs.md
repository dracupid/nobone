![nobone](assets/img/nobone.png)


## Overview

A server library tries to understand what developers really need.

The philosophy behind NoBone is providing possibilities rather than
telling developers what they should do. All the default behaviors are
just examples of how to use NoBone. All the APIs should dance together
happily. So other than js, the idea should be ported to any other language easily.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956)

*****************************************************************************

## Features

* Code you program, not configure.
* Build for performance.
* Not only a good dev-tool, but also works great on production.
* Cross platform of course.

*****************************************************************************

## Install

Install as an dependency:

```shell
npm install nobone

# View a better nobone documentation than Github readme.
node_modules/.bin/nobone --doc
```

Or you can install it globally:

```shell
npm i -g nobone

# View a better nobone documentation than Github readme.
nobone -d
```

*****************************************************************************

## Quick Start

For more examples, go through the [examples](examples) folder.

```coffee
<%- usage %>
```

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
log_reg='.ejs' nobone

# Use custom logic to start up.
nobone app.js

# Scaffolding helper
nobone bone -h

```

*****************************************************************************

## FAQ

<%- faq %>

*****************************************************************************

## Modules API

<%- mods_api %>

## Changelog

See the [doc/changelog.md](https://github.com/ysmood/nobone/blob/master/doc/changelog.md) file.

*****************************************************************************

## Unit Test

  npm test

*****************************************************************************

## Benchmark

<% benchmark.forEach(function (el) { %>
<%- el.description %>
<% }) %>

*****************************************************************************

## Road Map

Decouple libs.

Better test coverage.

*****************************************************************************

## Lisence

### BSD

May 2014, Yad Smood
