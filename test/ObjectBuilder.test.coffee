util = require 'util'
assert = require 'assert'
{file} = require('./ext/ext') ext : 'coffee'
ObjectBuilder = require './../lib/ObjectBuilder'
prettyjson = require 'prettyjson'

describe 'ObjectBuilder', ->
  it 'should build an object', ->
    builder = new ObjectBuilder()
    v = builder.build file 'xml'
    #console.log prettyjson.render builder.object
    console.log util.inspect v, depth : 10
