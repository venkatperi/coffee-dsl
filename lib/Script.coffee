{EventEmitter} = require 'events'
_ = require 'lodash'
vm = require 'vm'
CoffeeScript = require 'coffee-script'
Context = require './Context'

symbols =
  println : console.log
  console : console
  Object : Object

handler = ( script, calls ) ->
  get : ( t, k ) ->
    for obj in script.context.stack
      if _.has obj, k
        return  obj[ k ]
        #console.log k, typeof v
        #return v unless k in calls
        #return v if typeof v is 'function'
        #console.log k
        #return obj.methodMissing?(k)
        #( x ) -> obj[ k ] = x

    return script.methodMissing k if k in calls
    script.propertyMissing(k)

  set : ( t, k, v ) ->
    #console.log "set: #{k}, #{v}"
    for r in script.context.stack when _.has r, k
      return r[ k ] = v
    script.context.top()[ k ] = v

class Script extends EventEmitter
  constructor : ->
    @symbols = _.extend symbols
    @binding = {}
    @context = new Context()
    @context.push @symbols
    @context.push @
    @context.push @binding

  evaluate : ( input ) =>
    tokens = CoffeeScript.tokens input
    locals = r = []

    calls = []
    for t,i in tokens when t[ 0 ] is 'IDENTIFIER'
      unless t[ 1 ][ 0 ] is '_'
        locals.push t[ 1 ]
        if tokens[ i + 1 ][ 0 ] is 'CALL_START'
          calls.push t[ 1 ]

    locals = _.uniq locals
    calls = _.uniq calls

    ast = CoffeeScript.nodes tokens
    #console.log calls
    js = ast.compile bare : yes, locals : locals
    #console.log js
    sandbox = new Proxy @binding, handler(@, calls)
    vm.createContext sandbox
    vm.runInContext js, sandbox
    @emit 'evaluated', @binding
    @binding


  methodMissing : ( name ) => ( args... ) =>
    #console.log "method missing: #{name}, #{JSON.stringify args}"

  propertyMissing : ( name ) =>
    #console.log "property missing: #{name}"

module.exports = Script