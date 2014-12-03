- v1.0.7

  - Fixed a empty static file bug.
  - Removed the `stylus` and `uglify-js` deps.
  - Update deps: `express`, `which`, `jdb`, `glob`.
  - Optimize the `kit.monitorApp`, `kit.open`.
  - Optimize the static server style.
  - Fix a plugin path bug.
  - Fix a watch dir bug.

- v0.9.8

  - Auto check new version of nobone.
  - Use camelized API.
  - Fixed a `kit.watchDir` bug.

- v0.9.5

  - Now the `dependencyRoots` can only be an array.
  - Better language api.
  - Fix a `less` compiler bug.
  - Add 'compiled' event to renderer.
  - Better render performance under burst requests.
  - Now `kit.request` supports transport progress.
  - Add `lang` module.
  - Fix some cache issues.

- v0.9.1

  - Optimize `proxy.url`.
  - Update dependencies.
  - Minor changes.

- v0.8.6

  - `renderer.static` add `brwoserify` support. Use `.jsb` extension to take advantage of this bundle helper.
  - More friendly `kit.monitorApp` info.

- v0.8.5

  - Better language API.
  - Add `reqPathHandler` option to `renderer.static`.

- v0.8.4

  - Fix `kit.monitorApp` a restart ended process bug.
  - Add auto-compiled code file system cache, better restart performance.
  - Update dependencies.
  - Fix a `kit.log` trace and regex conflict bug.
  - Update the source map API.
  - The `kit.watchDir` now automatically watches file's parent folder.

- v0.8.2

  - `kit.open` now supports Linux.
  - Fix a Windows spawn pid bug.
  - Update dependencies.

- v0.8.1

  - Fix a fatal bug of Rendreer's promise rejection.

- v0.8.0

  - Replace Q with ES6 style promise.

- v0.7.9

  - Fix a fatal bug of syntax using.
  - Optimize the watch mechanism.

- v0.7.8

  - Fix a less dependency pattern bug.
  - Add dependency roots option for `FileHandler`.
  - Fix a cake path issue.
  - Update stylus.

- v0.7.5

  - Add `kit.exec` helper.
  - Add renderer cache limitation.
  - Update `stylus` to `v0.49.0`.
  - Fix a watch bug of renderer.

- v0.7.3

  - Update `jdb` to `v0.3.1`.
  - Update `express` to `v4.9.4`.
  - Update `serve-index` to `v1.3.0`.
  - Rename `sendfile` t `sendFile`.

- v0.7.2

  - Fix a cache default option bug.

- v0.7.1

  - Fix a file extension bug.
  - Optimize `kit.err`.
  - Update stylus to `0.48.1`.

- v0.7.0

  - `proxy` now support bandwidth limitation.
  - CLI add interactive mode.
  - Update coffee-script version.

- v0.6.9

  - Fix a linux process exit bug.

- v0.6.7

  - Optimize the performance of `kit.async`.
  - Optimize documentation.

- v0.6.5

  - Fix a renderer extension name bug.

- v0.6.4

  - Optimize dependency regex.

- v0.6.3

  - Fix a dependency watch bug.
  - Fix a sass compiler bug.

- v0.6.1

  - Optimize the auto-reload of entrance file or plugin.

- v0.6.0

  - Fix a auto-reload bug.

- v0.5.9

  - Fix a fatal bug of caching static file.

- v0.5.8

  - Now nobone supports plugin.

- v0.5.6

  - Fix a auto reload bug.
  - Optimize the renderer api.

- v0.5.5

  - Delete the `html-minifier` module.
  - Add the `kit.encrypt` and `kit.decrypt`.
  - Add `kit.watchDir`.
  - Better renderer memory management.

- v0.5.4

  - Expose lodash as `kit._`.
  - Better nobone client api.
  - Now on dev mode default `Access-Control-Allow-Origin` is allow all.

- v0.5.3

  - Fix rewatching empty cache bug.
  - Add a `kit.unwatch` api.
  - Fix a unwatch bug.
  - Fix a doc path bug.

- v0.5.2

  - Add retry time option for see.
  - Add default sass support.
  - Add auto dependency watch support.
  - Optimize markdown style.

- v0.5.0

  - Fix a markdown cache bug.
  - Update documentation.

- v0.4.9

  - Fix a file watch concurrent lock issue.

- v0.4.8

  - Optimize the `kit.async` api.

- v0.4.7

  - Optimize the performance of auto-reload.
  - Fix a `render` option default value bug.

- v0.4.6

  - Add cli '-d --doc' option.

- v0.4.5

  - Fix a etag bug of ejs compiler.

- v0.4.4

 - Big Change: the `renderer.render` API. For example, now directly render
   a ejs file should use 'a.html', not 'a.ejs'.
   Or you can use `renderer.render('a.ejs', '.html')` to force '.html' output.

- v0.4.2

  - A more powerful bone template.
  - Fix a cwd fatal bug.

- v0.3.9

  - Add a language helper.
  - Add minify support for html, js, css.

- v0.3.8

  - Fix a node v0.8 path delimiter bug.
  - Now `kit.request` will auto handle `application/x-www-form-urlencoded`
    when `reqData` is an object.
  - Optimize `proxy.pac` helper.

- v0.3.7

  - Add `proxy.pac` helper.
  - Fix a `serve-index` bug.
  - `kit.request` auto-redirect support.
  - A better API for `noboenClient.js` injection.

- v0.3.6

  - Fix a `kit.log` bug.
  - Optimize proxy functions.
  - Optimize `kit.request`.

- v0.3.4

  - Add `proxy.connect` helper.

- v0.3.3

  - Optimize the noboneClient handler. Make it more smart.
  - Add renderer context to the compiler function.

- v0.3.2

  - Fix a autoReload bug.
  - Update jdb.

- v0.3.1

  - Fix a renderer bug.
  - Optimize markdown style.

- v0.3.0

  - Fix a memory leak bug.
  - Fix log time bug.
  - Add http proxy tunnel support.
  - Optimize the `fs` API.

- v0.2.9

  - Optimize documentation.
  - Remove the `less` dependency.

- v0.2.8

  - Some other minor changes.
  - Add `kit.request` helper.
  - Add `kit.open` helper.
  - Optimize the template of `bone`.

- v0.2.7

  - Fix an URI encode bug.
  - Better etag method.
  - Better `kit.spawn`.

- v0.2.6

  - Add a remote log helper.
  - Refactor `renderer.autoReload()` to `nobone.client()`.

- v0.2.4 - v0.2.5

  - Fix a windows path issue.

- v0.2.3

  - Support directory indexing.
  - Proxy better error handling.

- v0.2.2

  - Add a delay proxy helper.

- v0.2.1

  - Much faster way to handle Etag.

- v0.2.0

  - Decouple Socket.io, use EventSource instead.
  - Refactor `codeHandlers` to `fileHandlers`.
  - Optimize style and some default values.

- v0.1.9

  - Minor change.

- v0.1.8

  - Now renderer support for binary file, such as image.
  - Auto reload page is even smarter, when dealing with css or image,
    the browser is updated instantly without reloading the page.

- v0.1.7

  - Add support for less.
  - Add extra codeHandler watch list. (solve compile dependency issue)

- v0.1.6

  - Optimize `kit.parseComment`.

- v0.1.5

  - Change markdown extension from `mdx` to `md`.

- v0.1.4

  - Fix some minor renderer bugs.
  - Fix a `kit.require` fatal bug.
  - Add two file system functions to `kit`.

- v0.1.3

  - Change API `nobone.create()` to `nobone()`.
  - Better error handling.
  - Optimize markdown style.

- v0.1.2

  - Support for markdown.

- v0.1.1

  - Fix a renderer bug which will cause watcher fails.
  - Optimize documentation.
