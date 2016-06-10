Clock = require './Clock'
vm = require('vm')
code = 'var square = n * n;'
fn = new Function('n', code)
script = vm.createScript(code)
console.log script
sandbox = undefined
n = 5
sandbox = n: n

benchmark = (title, funk) ->
  clock = new Clock()
  i = 0
  while i < 5000
    funk()
    i++
  console.log title + ': ' + clock.pretty
  return

ctx = vm.createContext(sandbox)
#benchmark 'vm.runInThisContext', -> vm.runInThisContext code
benchmark 'vm.runInNewContext', -> vm.runInNewContext code, sandbox
#benchmark 'script.runInThisContext', -> script.runInThisContext()
benchmark 'script.runInNewContext', -> script.runInNewContext sandbox
benchmark 'script.runInContext', -> script.runInContext ctx
benchmark 'fn', -> fn n

