[![nobone](assets/img/nobone.png?noboneAssets)](https://github.com/ysmood/nobone)


## Overview

A server library tries to understand what developers really need.

The philosophy behind NoBone is providing possibilities rather than
telling developers what they should do. All the default behaviors are
just examples of how to use NoBone. All the APIs should work together
without pain.

[![NPM version](https://badge.fury.io/js/nobone.svg)](http://badge.fury.io/js/nobone) [![Build Status](https://travis-ci.org/ysmood/nobone.svg)](https://travis-ci.org/ysmood/nobone) [![Build status](https://ci.appveyor.com/api/projects/status/5puu5bouyhrmcymj)](https://ci.appveyor.com/project/ysmood/nobone-956) [![Deps Up to Date](https://david-dm.org/ysmood/nobone.svg?style=flat)](https://david-dm.org/ysmood/nobone)

*****************************************************************************

## Features

* Code you program, not configure.
* Built for performance.
* Not only a good dev-tool, but also good at production.
* Supports programmable plugins.
* Cross platform.
* Pure js, supports coffee by default.

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
nb -d
```

*****************************************************************************

## FAQ

<%= faq %>

*****************************************************************************

## Quick Start

```coffee
<%= basic %>
```

*****************************************************************************

## Tutorials

### Code Examples

See the [examples](examples).

<%= examples %>

### CLI Usage

You can use nobone as an alternative of `node` bin or `coffee`, it will auto detect file type and run it properly.

#### Run Script

Such as `nb app.js`, `nb app.coffee`. It will run the script and if
the script changed, it will automatically restart it.

You can use `nb -w off app.js` to turn off the watcher.
You can pass a json to the watch list `nb -w '["a.js", "b.js"]' app.js`.
Any of watched file changed, the program will be restarted.

#### Static Folder Server

Such as `nb /home/`, it will open a web server for you to browse the folder content. As you edit the html file in the folder, nobone will live
reload the content for you. For css or image file change, it won't refresh the whole page, only js file change will trigger the page reload.

You can use url query `?source` and url hash `#L` to view a source file.
Such as `http://127.0.0.1:8013/app.js?source#L10`,
it will open a html page with syntax highlight.
Or full version `http://127.0.0.1:8013/app.js?source=javascript#L10`

You can use `?gotoDoc` to open a dependencies' markdown file. Such as `jdb/readme.md?gotoDoc`. Nobone will use the node require's algorithm to search for the module recursively.

*****************************************************************************

## CLI

Install nobone globally: `npm install -g nobone`

```bash
# Help info
nb -h

# Use it as a static file server for current directory.
# Visit 'http://127.0.0.1/nobone' to see a better nobone documentation.
nb

# Use regex to filter the log info.
# Print out all the log if it contains '.ejs'
logReg='.ejs' nb

# Use custom logic to start up.
nb app.js
watchPersistent=off nb app.js

# Scaffolding helper
nb bone -h

```

*****************************************************************************

## Plugin

Here I give a simple instruction. For a real example, see [nobone-sync](https://github.com/ysmood/nobone-sync).

### Package config

NoBone support a simple way to implement npm plugin. And your npm package doesn't have to waist time to install nobone dependencies. The `package.json` file can only have these properties:

```javascript
{
  "name": "nobone-sample",
  "version": "0.0.1",
  "description": "A sample nobone plugin.",
  "main": "main.coffee"
}
```

The `name` of the plugin should prefixed with `nobone-`.

### Main Entrance File

The `main.coffee` file may looks like:

```coffee
{ kit } = require 'nobone'
kit.log 'sample plugin'
```

### Use A Plugin

Suppose we have published the `nobone-sampe` plugin with npm.

Other people can use the plugin after installing it with either `npm install nobone-sample` or `npm install -g nobone-sample`.

To run the plugin simply use `nobone sample`.

You can use `nb ls` to list all installed plugins.

*****************************************************************************

## Modules API

_It's highly recommended reading the API doc locally by command `nb --doc`_

<%= modsApi %>

## Changelog

See the [doc/changelog.md](doc/changelog.md) file.

*****************************************************************************

## Unit Test

```shell
npm test
```

*****************************************************************************

## Benchmark

Goto see [benchmark](benchmark)

*****************************************************************************

## Road Map

Decouple libs.

Better test coverage.

*****************************************************************************

## Lisence

### BSD

May 2014, Yad Smood
