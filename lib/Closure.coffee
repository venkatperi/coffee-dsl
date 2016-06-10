vm = require 'vm'
esprima = require 'esprima'
tosource = require 'tosource'
esquery = require 'esquery'

RESOLVE_STRATEGY = {
  OwnerFirst : 'OwnerFirst'
  DelegateFirst : 'DelegateFirst'
  OwnerOnly : 'OwnerOnly'
  DelegateOnly : 'DelegateOnly'
  ToSelf : 'ToSelf'
}

handler = ( closure, calls = [] ) ->
  get : ( t, k ) ->
    return closure.invokeMethod k if k in calls
    closure.getProperty(k)

  set : ( t, k, v ) ->
    closure.setProperty k, v

class Closure

  @property = ( name, opts ) ->
    Object.defineProperty @prototype, name, opts

  @RESOLVE_STRATEGY : RESOLVE_STRATEGY

  constructor : ( @fn, @owner ) ->
    @analyzeFn()
    @resolveStrategy = RESOLVE_STRATEGY.OwnerFirst
    @delegate = undefined
    @binding = {}
    @context = new Proxy @binding, handler(@)
    vm.createContext @context

  analyzeFn : =>
    @source = tosource @fn
    @ast = esprima.parse @source
    @calls = esquery @ast, 'CallExpression'

  call : =>
    vm.runInContext @fn, @context

  getProperty : ( name ) =>
    switch name
      when 'delegate' then @delegate
      when 'owner' then @owner
      else
        switch @resolveStrategy
          when 1 then @getPropertyDelegateFirst name
          else
            @getPropertyOwnerFirst name

  setProperty : ( name ) =>
    switch name
      when 'delegate' then @delegate
      when 'owner' then @owner
      else
        switch @resolveStrategy
          when 1 then @getPropertyDelegateFirst name
          else
            @getPropertyOwnerFirst name

  getPropertyDelegateFirst : ( name ) =>
    @getPropertyTryThese name, @delegate, @owner

  getPropertyOwnerFirst : ( name ) =>
    @getPropertyTryThese name, @owner, @delegate

  getPropertyTryThese : ( name, items... ) =>
    for i in items when i?
      return i[ name ] if _.has i, name
    throw new ReferenceError name

module.exports = Closure