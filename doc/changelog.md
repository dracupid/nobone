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
    when `req_data` is an object.
  - Optimize `proxy.pac` helper.

- v0.3.7

  - Add `proxy.pac` helper.
  - Fix a `serve-index` bug.
  - `kit.request` auto-redirect support.
  - A better API for `noboen_client.js` injection.

- v0.3.6

  - Fix a `kit.log` bug.
  - Optimize proxy functions.
  - Optimize `kit.request`.

- v0.3.4

  - Add `proxy.connect` helper.

- v0.3.3

  - Optimize the nobone_client handler. Make it more smart.
  - Add renderer context to the compiler function.

- v0.3.2

  - Fix a auto_reload bug.
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
  - Refactor `renderer.auto_reload()` to `nobone.client()`.

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
  - Refactor `code_handlers` to `file_handlers`.
  - Optimize style and some default values.

- v0.1.9

  - Minor change.

- v0.1.8

  - Now renderer support for binary file, such as image.
  - Auto reload page is even smarter, when dealing with css or image,
    the browser is updated instantly without reloading the page.

- v0.1.7

  - Add support for less.
  - Add extra code_handler watch list. (solve compile dependency issue)

- v0.1.6

  - Optimize `kit.parse_comment`.

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
