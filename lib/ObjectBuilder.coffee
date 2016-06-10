_ = require 'lodash'
Script = require './Script'
Stack = require './Stack'

log = ( v ) -> console.log JSON.stringify v, null, 0

class ObjectBuilder extends Script
  constructor : ->
    super()
    @object = {}
    @stack = new Stack()
    @stack.push @object

  build : ( xml ) =>
    @evaluate xml
    @object

  methodMissing : ( name ) => ( args... ) =>
    obj = {}
    unless typeof args[ 0 ] is 'function'
      obj.__attr = {}
      for own k,v of args[0]
        obj.__attr[k] = v
      args.shift()

    return unless typeof args[ 0 ] is 'function'

    @stack.push obj
    val = @context.runWith args[ 0 ] if args.length
    @stack.pop()

    if _.isEmpty obj
      obj = val
    else if !_.isObjectLike val
      obj.__content = val

    top = @stack.top

    unless top[ name ]?
      top[ name ] = obj
    else
      unless Array.isArray top[ name ]
        top[ name ] = [ top[ name ] ]
      top[ name ].push obj

    top

  propertyMissing : ( name ) =>
    console.log name

module.exports = ObjectBuilder

