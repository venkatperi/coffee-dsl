_ = require 'lodash'
JSInterpreter = require './JSInterpreter'
log = require('taglog') 'FactoryBuilderSupport'
getClass = require 'what-class'
{inspect} = require './util/util'
rek = require 'rekuire'
log = rek('logger')(require('path').basename(__filename).split('.')[0])
log.level 'verbose'

CURRENT_NODE = '_CURRENT_NODE_'
PARENT_FACTORY = '_PARENT_FACTORY_'
PARENT_NODE = '_PARENT_NODE_'
PARENT_CONTEXT = '_PARENT_CONTEXT_'
PARENT_NAME = '_PARENT_NAME_'
PARENT_BUILDER = '_PARENT_BUILDER_'
CURRENT_BUILDER = '_CURRENT_BUILDER_'
CURRENT_FACTORY = '_CURRENT_FACTORY_'
CURRENT_NAME = '_CURRENT_NAME_'
CHILD_BUILDER = '_CHILD_BUILDER_'

isFunction = ( f ) ->
  f?.type is 'function' or _.isFunction(f)

class FactoryBuilderSupport extends JSInterpreter

  @property = ( name, opts ) ->
    Object.defineProperty @prototype, name, opts

  @property 'context', get : -> @contexts[ 0 ]
  @property 'current', get : -> @getContextAttribute CURRENT_NODE
  @property 'currentName', get : -> @getContextAttribute CURRENT_NAME
  @property 'parentFactory', get : -> @getContextAttribute PARENT_FACTORY
  @property 'parentNode', get : -> @getContextAttribute PARENT_NODE
  @property 'parentContext', get : -> @getContextAttribute PARENT_CONTEXT
  @property 'parentName', get : -> @getContextAttribute PARENT_NAME
  @property 'parentBuilder', get : -> @getContextAttribute PARENT_BUILDER
  @property 'currentFactory', get : -> @getContextAttribute CURRENT_FACTORY
  @property 'childBuilder', get : -> @getContextAttribute CHILD_BUILDER

  @property 'proxyBuilder',
    get : -> @ #@localProxyBuilder ? @globalProxyBuilder
    set : ( v ) -> @globalProxyBuilder = v

  constructor : () ->
    log.v 'ctor()'
    super()
    @contexts = []
    @factories = new Map()
    @explicitProperties = new Map()
    @explicitMethods = new Map()
    #@current = undefined # current node
    #@currentFactory = undefined # factory that built current node
    #@currentBuilder = undefined
    #@childBuilder = undefined
    @globalProxyBuilder = @
    @preInstantiateDelegates = []
    @postInstantiateDelegates = []
    @postNodeCompletionDelegates = []

  getContextAttribute : ( k ) =>
    @context?.get k

  getName : ( name ) =>
    @proxyBuilder.nameMappingClosure?(name) or name

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
    log.v 'createNode', name
    
    factory = @proxyBuilder.resolveFactory name
    unless factory?
      throw new Error "Missing method: #{name}, #{inspect attr}"

    @proxyBuilder.context.set CURRENT_FACTORY, factory
    @proxyBuilder.context.set CURRENT_NAME, name
    @proxyBuilder.preInstantiate name, attr, value

    try
      node = factory.newInstance @proxyBuilder.childBuilder, name, value, attr
      unless node
        log.w "Factory for #{name} returned null."
        return
    catch err
      console.log err
      throw new Error "Failed to create component for #{name}.\n#{err.message}"

    @proxyBuilder.postInstantiate name, attr, node
    #@proxyBuilder.handleNodeAttributes node, attr
    node

  resolveFactory : ( name ) =>
    @context.set CHILD_BUILDER, @proxyBuilder
    @proxyBuilder.factories.get name

  dispatchNodeCall : ( name, args ) =>
    log.v 'dispatchNodeCall', name, args
    closure = undefined
    list = args
    needToPopContext = false
    if @proxyBuilder.contexts.length is 0
      @proxyBuilder.newContext()
      needToPopContext = true

    node = undefined
    try
      arg = undefined
      namedArgs = {}

      if list.length
        if typeof list[ 0 ] is 'string'
          arg = list.shift()
          
      if list.length and !isFunction(list[ 0 ]) 
        namedArgs = list.shift()

      if list.length and isFunction list[ list.length - 1 ]
        closure = list[ list.length - 1 ]
        list = list[ ..-2 ]

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
            ctx.set CURRENT_NODE, node
            ctx.set PARENT_FACTORY, parentFactory
            ctx.set PARENT_NODE, current
            ctx.set PARENT_CONTEXT, parentContext
            ctx.set PARENT_NAME, parentName
            ctx.set PARENT_BUILDER, parentContext.get CURRENT_BUILDER
            ctx.set CURRENT_BUILDER, parentContext.get CHILD_BUILDER
            log.v "Configuring node: #{name}"
            @callScriptMethod node, closure
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

  popContext : =>
    contexts = @proxyBuilder.contexts
    contexts.shift() if contexts.length

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
    @proxyBuilder.currentFactory.onNodeCompleted @proxyBuilder.childBuilder, parent, node

  setParent : ( parent, child ) =>
    @proxyBuilder.currentFactory.setParent @proxyBuilder.childBuilder, parent, child
    parentFactory = @proxyBuilder.parentFactory
    if parentFactory
      parentFactory.setChild @proxyBuilder.currentBuilder, parent, child

  invokeMethod : ( methodName, args ) =>
    log.v 'invokeMethod', methodName
    name = @proxyBuilder.getName methodName
    previousContext = @proxyBuilder.context

    try
      @proxyBuilder.doInvokeMethod methodName, name, args
    catch err
      if previousContext in @contexts
        ctx = @proxyBuilder.context
        while (ctx and ctx != previousContext)
          @proxyBuilder.popContext()
          ctx = @proxyBuilder.context
      throw err
    undefined

  doInvokeMethod : ( methodName, name, args ) =>
    @dispatchNodeCall name, args

  setClosureDelegate : ( closure, node ) =>
    @setDelegate closure, node

  build : ( script, opts ) =>
    @evaluate script, opts

module.exports = FactoryBuilderSupport

#code = """
#task copy, type: Copy, -> println 'configuring task'
#
#"""
#
#builder = new FactoryBuilderSupport().build code, coffee : true
