class Stack
  Object.defineProperty @prototype, 'top', get : -> @peek()
  Object.defineProperty @prototype, 'size', get : -> @data.length

  constructor : ->
    @data = []

  push : ( e ) => @data.splice 0, 0, e
  pop : =>
    throw new Error "Stack is empty" unless @data.length
    @data.shift()

  peek : =>
    throw new Error "Stack is empty" unless @data.length
    @data[ 0 ]

  empty : => @data.length is 0

module.exports = Stack