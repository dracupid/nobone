foo = require './bundleFoo'


elem = document.createElement 'p'
elem.textContent = 'bundle test: ' + foo.bar
document.body.appendChild elem
