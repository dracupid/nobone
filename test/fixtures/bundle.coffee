foo = require './bundle_foo'


elem = document.createElement 'p'
elem.textContent = 'bundle test: ' + foo.bar
document.body.appendChild elem
