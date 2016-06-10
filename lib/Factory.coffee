class Factory
  ###
  Public: Return true if no child closures should be processed
  ###
  isLeaf : ->
    throw new Error "Virtual function called"

  ###
  Public: Does this factory 'own' its child's closure
  ###
  handlesNodeChildren : ->
    throw new Error "Virtual function called"

  ###
  Public: Called to create a new node
  
  description
  ###
  newInstance : ( builder, name, attr )->
    throw new Error "Virtual function called"

  ###
  Public: Called when a factory is registered to a builder
  ###
  onFactoryRegistration : ( builder, name, attr )->
    throw new Error "Virtual function called"

  ###
  Public: Returns true if the factory builder should use standard bean property
   matching for the remaining attributes
  ###
  onHandleNodeAttributes : ( builder, node, attr ) ->
    throw new Error "Virtual function called"

  ###
  Public: Only called if it isLeaf is false and isHandlesNodeChildren is true
  ###
  onNodeChildren : ( builder, node, childClosure ) ->
    throw new Error "Virtual function called"

  onNodeCompleted : ( builder parent, node ) ->
    throw new Error "Virtual function called"

  setChild : ( builder, parent, child ) ->
    throw new Error "Virtual function called"

  setParent : ( builder, parent, child ) ->
    throw new Error "Virtual function called"

module.exports = Factory