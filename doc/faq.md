0. How to view the documentation with TOC (table of contents) or offline?

  > If you have installed nobone globally,
  > just execute `nobone -d`. If you are on Windows or Mac,
  > it will auto open the documentation.

  > If you have installed nobone with `npm install nobone` in current
  > directory, execute `node_modules/.bin/nobone -d`.

0. The documentation looks weird on Github.

  > Yes, please see the FAQ 1 and use offline documentation.

0. Why I can't execute the entrance file with nobone cli tool?

  > Don't execute `nobone` with a directory path when you want to start it with
  > an entrance file.

0. Why doesn't the auto-reaload work?

  > Check if the `process.env.NODE_ENV` is set to `development`.

0. When serving `jade` or `less`, it doesn't work.

  > These are optinal packages, you have to install them first.
  > For example, if you want nobone to support `jade`: `npm install -g jade`.


