* v0.2.8

  * Some other minor changes.
  * Add `kit.request` helper.
  * Add `kit.open` helper.
  * Optimize the template of `bone`.

* v0.2.7

  * Fix an URI encode bug.
  * Better etag method.
  * Better `kit.spawn`.

* v0.2.6

  * Add a remote log helper.
  * Refactor `renderer.auto_reload()` to `nobone.client()`.

* v0.2.4 - v0.2.5

  * Fix a windows path issue.

* v0.2.3

  * Support directory indexing.
  * Proxy better error handling.

* v0.2.2

  * Add a delay proxy helper.

* v0.2.1

  * Much faster way to handle Etag.

* v0.2.0

  * Decouple Socket.io, use EventSource instead.
  * Refactor `code_handlers` to `file_handlers`.
  * Optimize style and some default values.

* v0.1.9

  * Minor change.

* v0.1.8

  * Now renderer support for binary file, such as image.
  * Auto reload page is even smarter, when dealing with css or image,
    the browser is updated instantly without reloading the page.

* v0.1.7

  * Add support for less.
  * Add extra code_handler watch list. (solve compile dependency issue)

* v0.1.6

  * Optimize `kit.parse_comment`.

* v0.1.5

  * Change markdown extension from `mdx` to `md`.

* v0.1.4

  * Fix some minor renderer bugs.
  * Fix a `kit.require` fatal bug.
  * Add two file system functions to `kit`.

* v0.1.3

  * Change API `nobone.create()` to `nobone()`.
  * Better error handling.
  * Optimize markdown style.

* v0.1.2

  * Support for markdown.

* v0.1.1

  * Fix a renderer bug which will cause watcher fails.
  * Optimize documentation.
