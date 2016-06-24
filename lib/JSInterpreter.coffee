{Interpreter, DefaultDelegate} = require 'JS-Interpreter'
util = require 'util'
compileCoffee = require './compile-coffee'
Q = require 'q'

println = -> console.log.apply console, Array.from arguments

class JSInterpreter extends DefaultDelegate
  constructor : ->
    @methods = []
    @properties = []

  evaluate : ( code, opts = {} ) =>
    code = compileCoffee(code) if opts.coffee

    @interpreter = new Interpreter code, ( ip, scope ) =>
      @scope = scope
      ip.setProperty scope, 'delegate', @
      ip.setNativeFn scope, 'println', println

    @asyncRun()

  asyncRun : =>
    new Q.Promise ( resolve, reject ) =>
      @interpreter.asyncRun resolve

  callScriptMethod : ( delegate, fn, args... ) =>
    @interpreter.callScriptMethod delegate, fn, args

  setDelegate : ( fn, handler ) =>
    throw new Error "delegate is null" unless handler
    throw new Error "not a sandbox function" unless fn.type is 'function'
    ip = @interpreter
    fn.node.__delegate = new DefaultDelegate(ip, handler)

module.exports = JSInterpreter

