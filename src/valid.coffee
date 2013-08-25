Lazy = require('lazy.js')
validator = require('validator')

###
Wrap node-validator methods for use with Derby
###

check = (model, callback) ->
  try
    callback( validator.check(model.get 'input') )
    model.del('errors')
    true
  catch err
    model.set('errors', err.message)
    false

sanitize = (model, callback) ->
  safe = callback( validator.sanitize(model.get 'input') )
  model.set('input', safe) if safe?

###
Define data types using validations
###

isEmail = (model) ->
  sanitize model, (input) ->
    input.trim()
  check model, (input) ->
    input.isEmail()

isPassword = (model) ->
  check model, (input) ->
    input.len(6)

###
Map data types to schema keys
###

validate = (key, model, schema) ->
  switch schema[key]
    when 'email'
      isEmail(model.at key)
    when 'password'
      isPassword(model.at key)

###
Perform field validation lazily in an attempt
to avoid overwhelming users with error messages.

returns true if model conforms to schema
###

module.exports = (model, schema, next) ->
  not Lazy(schema).keys().map(
    (key) -> validate(key, model, schema)
  ).any(
    (result) -> result is false
  )

