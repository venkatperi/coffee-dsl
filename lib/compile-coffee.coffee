_ = require 'lodash'
CoffeeScript = require 'coffee-script'

module.exports = ( input, opts = {} ) ->
  throw new Error "input must be a string" unless typeof input is 'string'
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
  opts = _.extend opts, bare : yes, locals : locals
  ast.compile opts 
