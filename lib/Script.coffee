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
    #console.log "get: #{k.toString()}"
    for r in script.context.stack
      return r[ k ] if r[ k ]?
    if k in calls
      return script.methodMissing k
    script.propertyMissing(k)

  set : ( t, k, v ) ->
    #console.log "set: #{k}, #{v}"
    for r in script.context.stack when r[ k ]?
      return r[ k ] = v
    script.context.top()[ k ] = v

class Script
  constructor : ->
    @symbols = _.extend symbols
    @context = new Context()
    @context.push @symbols
    @context.push @
    @binding = {}

  evaluate : ( input ) =>
    tokens = CoffeeScript.tokens input
    locals = r = []

    calls = []
    for t,i in tokens when t.variable and r.indexOf(t[ 1 ]) < 0
      unless t[ 1 ][ 0 ] is '_'
        locals.push t[ 1 ]
        if tokens[ i + 1 ][ 0 ] is 'CALL_START'
          calls.push t[ 1 ]

    ast = CoffeeScript.nodes tokens
    js = ast.compile bare : yes, locals : locals
    sandbox = new Proxy @binding, handler(@, calls)
    vm.createContext sandbox
    vm.runInContext js, sandbox
    @binding

  methodMissing : ( name ) => ( args... ) =>
    #console.log "method missing: #{name}, #{JSON.stringify args}"

  propertyMissing : ( name ) =>
    #console.log "property missing: #{name}"

module.exports = Script