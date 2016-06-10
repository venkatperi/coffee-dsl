class Context
  constructor : -> @stack = []

  push : ( c ) => @stack.splice 0, 0, c

  top : => @stack[ 0 ]

  pop : => @stack.shift()

  runWith : ( f, ctx... ) =>
    @push c for c in ctx
    v = f()
    @pop() for c in ctx
    v

module.exports = Context
