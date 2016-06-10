log = require('taglog') 'FactoryBuilderSupport'
getClass = require 'what-class'

asList = ( obj ) ->
  return [] unless obj?
  return obj if Array.isArray obj
  [ obj ]

class FactoryBuilderSupport extends Script

  @property = ( name, opts ) ->
    Object.defineProperty @prototype, name, opts

  @property 'context', get : -> @contexts[ 0 ]

  @property 'proxyBuilder',
    get : -> @localProxyBuilder or @globalProxyBuilder
    set : ( v ) -> @globalProxyBuilder = v

  @property 'name',
    get : -> @proxyBuilder.nameMappingClosure?(name) or name

  constructor : () ->
    @contexts = []
    @factories = new Map()
    @explicitProperties = new Map()
    @explicitMethods = new Map()
    @current = undefined # current node
    @currentFactory = undefined # factory that built current node
    @currentBuilder = undefined
    @childBuilder = undefined
    @globalProxyBuilder = @

  addAttributeDelegate : ( f ) =>
    @attributeDelegates ?= []
    @attributeDelegates.splice 0, 0, f

  addPostInstantiateDelegate : ( f ) =>
    @postInstantiateDelegates ?= []
    @postInstantiateDelegates.splice 0, 0, f

  addPreInstantiateDelegate : ( f ) =>
    @preInstantiateDelegates ?= []
    @preInstantiateDelegates.splice 0, 0, f

  addPostNodeCompletionDelegate : ( f ) =>
    @postNodeCompletionDelegate ?= []
    @postNodeCompletionDelegate.splice 0, 0, f

  registerFactory : ( name, factory ) =>
    @factories.set name, factory

  createNode : ( name, attr, value ) =>
    factory = @proxyBuilder.resolveFactory name
    unless factory?
      throw new Error "Missing method: #{name}, #{attr}"

    @proxyBuilder.context.set '_CURRENT_FACTORY_', factory
    @proxyBuilder.context.set '_CURRENT_NAME_', name
    @proxyBuilder.preInstantiate name, attr, value

    try
      node = factory.newInstance builder.childBuilder, name, value, attr
      unless node
        log.w "Factory for #{name} returned null."
        return
    catch err
      throw new Error "Failed to create component for #{name}.\n#{err.message}"

    @proxyBuilder.postInstantiate name, attr, node
    @proxyBuilder.handleNodeAttributes node, attr

  resolveFactory : ( name ) =>
    @context.set '_CHILD_BUILDER_', @proxyBuilder
    @proxyBuilder.factories.get name

  dispatchNodeCall : ( name, args ) =>
    closure = undefined
    list = args
    needToPopContext = false
    if @proxyBuilder.contents.length is 0
      @proxyBuilder.newContext()
      needToPopContext = true

    node = undefined
    try
      namedArgs = new Map()
      if list.length and getClass(list[ 0 ]) is 'Object'
        namedArgs = list[ 0 ]
        list.shift()

      if list.length and _.isFunction list[ list.length - 1 ]
        closure = list[ list.length - 1 ]
        list = list[ ..-2 ]

      arg = null
      if list.length
        if list.length is 1
          arg = list[ 0 ]
        else
          arg = list

      node = @proxyBuilder.createNode name, namedArgs, arg
      current = @proxyBuilder.current
      if current?
        @proxyBuilder.setParent current, node

      if closure?
        parentFactory = @proxyBuilder.currentFactory
        if parentFactory.isLeaf()
          throw new Error "#{name} doesn't support nesting."

        processContent = true
        if parentFactory.handlesNodeChildren()
          processContent = parentFactory.onNodeChildren @, node, closure

        if processContent
          parentName = @proxyBuilder.currentName
          parentContext = @proxyBuilder.context
          @proxyBuilder.newContext()

          ctx = @proxyBuilder.context
          try
          #ctx.set 'owner' , closure.
            ctx.set '_CURRENT_NODE_', node
            ctx.set '_PARENT_FACTORY_', parentFactory
            ctx.set '_PARENT_NODE_', current
            ctx.set '_PARENT_CONTEXT_', parentContext
            ctx.set '_PARENT_NAME_', parentName
            ctx.set '_PARENT_BUILDER_', parentContext.get '_CURRENT_BUILDER_'
            ctx.set '_CURRENT_BUILDER_', parentContext.get '_CHILD_BUILDER_'
            #@proxyBuilder.setClosureDelegate closure, node
            closure()
          catch err
            console.log err
          finally
            @proxyBuilder.popContext()

      @proxyBuilder.nodeCompleted current, node
      @proxyBuilder.postNodeCompletion current, node
    catch err
      console.log err
    finally
      if needToPopContext
        @proxyBuilder.popContext()

    node

  newContext : =>
    ctx = new Map()
    @contexts.splice 0, 0, ctx
    ctx

  preInstantiate : ( name, attr, value ) =>
    for f in @preInstantiateDelegates
      f @, attr, value

  postInstantiate : ( name, attr, node ) =>
    for f in @postInstantiateDelegates
      f @, attr, node

  postNodeCompletion : ( parent, node ) =>
    for f in @postNodeCompletionDelegates
      f @, parent, node

  nodeCompleted : ( parent, node ) =>
    @proxyBuilder.currentFactory
    .onNodeCompleted @proxyBuilder.childBuilder, parent, node

  setParent : ( parent, child ) =>
    @proxyBuilder.currentFactory.setParent @proxyBuilder.childBuilder, parent, child
    parentFactory = @proxyBuilder.parentFactory
    if parentFactory
      parentFactory.setChild @proxyBuilder.currentBuilder, parent, child

  invokeMethod: (methodName, args) =>
    name = @proxyBuilder.getName methodName
    previousContext = @proxyBuilder.context
    
    try 
      return @proxyBuilder.doInvokeMethod methodName, name, args
    catch err
      if @contexts.has previousContext
        con
      
    
  build : ( script ) =>
    @evaluate script

module.exports = FactoryBuilderSupport