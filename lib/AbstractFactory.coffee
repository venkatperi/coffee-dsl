#Factory = require './Factory'

class AbstractFactory

  isLeaf : -> false
  handlesNodeChildren : -> false
  onFactoryRegistration : ->
  onHandleNodeAttributes : -> true
  onNodeChildren : -> true
  onNodeCompleted : ->
  setParent : ->
  setChild : ->

module.exports = AbstractFactory