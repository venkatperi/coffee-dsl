util = require 'util'

inspect = ( x ) -> util.inspect x, depth : 2

module.exports =
  inspect : inspect

