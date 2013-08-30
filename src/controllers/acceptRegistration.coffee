Lazy        = require('lazy.js')
credential  = require('credential')
valid       = require('../valid')

registrationSchema =
  username: 'email'
  password: 'password'

parseInput = (arg, req) ->
  req.body[arg] || req.query[arg]

ensureInput = ([input, field], res) ->
  if input? then input else res.send(400, "Missing #{field}")

fetchForm = (args..., req, res) ->
  Lazy(args).map(
    (arg) -> parseInput(arg, req)
  ).zip(args).collect(
    (data) -> ensureInput(data, res)
  ).toArray()

module.exports = (options) ->
  acceptRegistration = (req, res, next) ->
    unless req.irons?.getSession? and typeof req.irons.getSession is typeof Function
      throw new Error('use ironsModel() before acceptRegistration()')

    # Require cookies
    unless req.headers?.cookie?
      return res.send(400, 'Cookies are required to register.')

    # Prevent registrations by logged in users
    if (req.user?.get('id'))
      return res.send(403, 'Must be logged out to register.')

    [username, password, nonce] = fetchForm('username', 'password', 'nonce', req, res)
    return next unless username and password and nonce

    req.irons.fetchSession (err, session) ->
      return next(err) if err

      # perform validation
      form = session.at('forms.register')
      form.set('username.input', username)
      form.set('password.input', password) # security risk?
      unless valid(form, registrationSchema)
        return res.send 422, 'Please fix the errors and try again.'

      req.irons.fetchUserByEmail username, (err, user) ->
        return next(err) if err
        if user # handle pre-existing registration
          req.irons.checkPassword user, password, (err, isValid) ->
            if isValid
              req.login user, (err) ->
                return next(err) if err
                res.send 'Logged in! (Already registered)'
            else
              res.send 401, 'Already registered. Please check your email to continue.'
        else # perform registration
          req.irons.registerLocal username, password, (err, user) ->
            return next(err) if err
            req.login user, (err) ->
              return next(err) if err
              res.send 'Registered!'

