TypedError = require 'error/typed'
WrappedError = require 'error/wrapped'

InstantiationFailed = WrappedError({
  type : 'instantiationFailed',
  message : '{nodeType}>{origMessage}',
  nodeType : undefined
})

ConfigureFailed = WrappedError {
  type : 'configureFailed',
  message : '{origMessage}',
  nodeType : undefined
}

FactoryNotFound = TypedError {
  type : 'factoryNotFound',
  message : 'Factory not found for {name}({attr})'
  name : undefined
  attr : undefined
}

InvalidOperation = TypedError {
  type : 'invalidOperation',
  message : 'Factory not found for {name}({attr})'
  name : undefined
  attr : undefined
}

module.exports = {
  InstantiationFailed
  ConfigureFailed
  FactoryNotFound
}