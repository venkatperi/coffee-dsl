_ = require 'lodash'
Interpreter = require 'JS-interpreter'
CoffeeScript = require 'coffee-script'

code = """
println 1
fn = ->
  _x = 0
  println it
  println test

setDelegate fn
fn 'abc'

"""

# convert a value to pseudo values (for use inside the sandbox)
Interpreter::fromNative = ( value, noRecurse ) ->
  if typeof value is "function"
    return @wrapNativeFn value

  if !value or !_.isObjectLike(value)
    #if typeof value != "object" or value == null
    return @createPrimitive value

  if value instanceof Array
    pseudoArray = @createObject @ARRAY
    for item, i in value
      @setProperty pseudoArray, i, @fromNative item

    return pseudoArray

  pseudoObject = @createObject @OBJECT
  for key, val of value
    @setProperty pseudoObject, key, if noRecurse then val else @fromNative val

  return pseudoObject

# convert pseudo objects from the sandbox into real objects
Interpreter::toNative = ( value ) ->
  #return value unless value.type?
  return value.data if value.isPrimitive

  return value if value.type == "function"

  if value.length? # array
    newArray = []
    for i in [ 0...value.length ]
      newArray.push @toNative value.properties[ i ]

    return newArray

  newObject = {}
  for key, val of value.properties
    newObject[ key ] = @toNative val

  return newObject

# convert a list of arguments from pseudo to native (see toNative)
Interpreter::convertArgsToNative = ( args... ) ->
  nativeArgs = []
  for arg in args
    nativeArgs.push @toNative arg

  return nativeArgs

# fully wrap a native function to be used inside the interpreter
# parent: scope of the function to be added to
# name: name of the function in said scope
# fn: the native function
# thisObj: the `this` object the function should be called by
Interpreter::setNativeFn = ( parent, name, fn, thisObj ) ->
  @setProperty parent, name, @wrapNativeFn fn, thisObj

Interpreter::wrapNativeFn = ( fn, thisObj ) ->
  thisIP = @
  @createNativeFunction ( args... ) ->
    thisObj ?= @ if !@.NaN # don't convert window
    thisIP.fromNative fn.apply thisObj, thisIP.convertArgsToNative args...

# fully wrap an asynchronous native function, see wrapNativeFn
Interpreter::wrapNativeAsyncFn = ( parent, name, fn, thisObj ) ->
  thisIP = @
  @setProperty parent, name, @createAsyncFunction ( args..., callback ) ->
    thisObj ?= @ if !@.NaN # don't convert window
    nativeArgs = thisIP.convertArgsToNative args...
    nativeArgs.unshift ( result ) -> callback thisIP.fromNative(result), true
    fn.apply thisObj, nativeArgs
  return

# wrap a whole class, see wrapNativeFn (doesn't work with async functions)
# scope: the scope for the class to be added to
# name: name of the class in said scope
# $class: the native class instance
# fns: optional, list of names of functions to be wrapped
Interpreter::wrapClass = ( scope, name, $class, fns ) ->
  obj = @createObject @OBJECT
  @setProperty scope, name, obj

  if !fns?
    fns = []
    for key, fn of $class
      fns.push key if typeof fn == "function"

  for fn in fns
    @wrapNativeFn obj, fn, $class[ fn ], $class

# transfer object from the sandbox to the outside by name
Interpreter::retrieveObject = ( scope, name ) ->
  return @toNative @getProperty scope, name

# transfer object from the outside into the sandbox by name
Interpreter::transferObject = ( scope, name, obj ) ->
  @setProperty scope, name, @fromNative obj, scope, name
  return

compileCoffee = ( input ) ->
  tokens = CoffeeScript.tokens input
  locals = []
  calls = []
  for t,i in tokens when t[ 0 ] is 'IDENTIFIER'
    unless t[ 1 ][ 0 ] is '_'
      locals.push t[ 1 ]
      if tokens[ i + 1 ][ 0 ] is 'CALL_START'
        calls.push t[ 1 ]

  locals = _.uniq locals
  calls = _.uniq calls

  ast = CoffeeScript.nodes tokens
  ast.compile bare : yes, locals : locals

println = -> console.log.apply console, Array.from arguments
setDelegate = (ip) -> ( fn ) ->
  if fn.type is 'function'
    fn.node.__delegate = 
      getProperty : ( name ) -> ip.fromNative "prop #{name}"
      hasProperty : ( name ) -> name in [ 'test' ]

class JSInterpreter
  constructor : ( code, globals, opts ) ->

    code = compileCoffee(code) if opts.coffee

    @interpreter = new Interpreter code, ( ip, scope ) =>
      @scope = scope

      ip.setNativeFn scope, 'setDelegate', setDelegate ip
      ip.setNativeFn scope, 'println', println


  #test = ->
  #  console.log 'testing 123'
  #ip.setProperty(ip.FUNCTION, '__delegate',
  #  ip.createNativeFunction(test), false, true);

  run : => @interpreter.run()

module.exports = JSInterpreter

interpreter = new JSInterpreter code, null, coffee : true
interpreter.run()
