assert = require 'assert'
{file} = require('./ext/ext') ext : 'coffee'
Script = require './../lib/Script'

class CopyTask
  from : ( x ) ->
  into : ( x ) ->

class Test extends Script
  constructor : ->
    super()
    @_ext = {}
    @symbols.Copy = CopyTask
    @context.push @_ext

  ext : ( f ) => f()

  task : ( name, opts, f ) =>
    if Array.isArray name
      f = opts
      [name,opts] = name
    t = new opts.type()
    @context.runWith f, t
    t

  methodMissing : ( name ) => ( args... ) =>
    #console.log "method missing: #{name}, #{JSON.stringify args}"
    return [ name ] unless args.length
    args = args[ 0 ] if args.length is 1
    [ name, args ]

describe 'dsl', ->
  it 'should evaluate', ->
    test = new Test()
    v = test.evaluate file 'dsl1'
    assert v.b is 5
