class Context
  constructor : -> @stack = []
  push : ( c ) => @stack.splice 0, 0, c
  top : => @stack[ 0 ]
  pop : => @stack.shift()
  runWith : ( f, ctx ) =>
    @push ctx
    v = f()
    @pop()
    v

module.exports = Context
