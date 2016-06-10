pretty = require 'pretty-hrtime'

class Clock

  @property = ( name, opts ) ->
    Object.defineProperty @prototype, name, opts

  @property 'time', get : -> process.hrtime @start

  @property 'pretty', get : -> pretty @time

  constructor : () ->
    @start = process.hrtime()

module.exports = Clock