Lazy        = require('lazy.js')
valid       = require('../valid')

registrationSchema =
  username: 'email'
  password: 'password'

parseInput = (arg, req) ->
  req.body[arg] || req.query[arg]

ensureInput = ([input, field], res) ->
  if input?
    input
  else
    res.send 400, JSON.stringify
      userId: null
      toast:
        type: 'error'
        msg: "Missing #{field}"

fetchForm = (args..., req, res) ->
  Lazy(args).map(
    (arg) -> parseInput(arg, req)
  ).zip(args).collect(
    (data) -> ensureInput(data, res)
  ).toArray()

module.exports = (options) ->
  register = (req, res, next) ->
    unless req.irons?.getSession?
      throw new Error('use ironsModel() before register()')

    # Prevent registrations by logged in users
    if req.user?.get('id')
      return res.send 403, JSON.stringify
        userId: req.user.get('id')
        toast:
          type: 'error'
          msg: 'Must be logged out to register.'

    # Require cookies
    unless req.headers?.cookie?
      return res.send 400, JSON.stringify
        userId: null
        toast:
          type: 'error'
          msg: 'Cookies are required to register.'

    [username, password] = fetchForm('username', 'password', req, res)
    return next unless username and password

    req.irons.fetchSession (err, session) ->
      return next(err) if err

      # perform validation
      form = session.at('forms.register')
      form.set('username.input', username)
      form.set('password.input', password) # security risk?
      unless valid(form, registrationSchema)
        return res.send 422, JSON.stringify
          userId: null
          toast:
            type: 'error'
            msg: 'Please fix the errors and try again.'

      req.irons.fetchUserByEmail username, (err, user) ->
        return next(err) if err
        if user? # handle pre-existing registration
          req.irons.checkPassword user, password, (err, isValid) ->
            if isValid
              return next(err) if err
              req.login user, (err) ->
                return next(err) if err
                res.send JSON.stringify
                  userId: user.get('id')
                  toast:
                    type: 'success'
                    msg: 'Logged in! (Already registered)'
            else
              res.send 401, JSON.stringify
                userId: null
                toast:
                  type: 'error'
                  msg: 'Already registered. Please check your email to continue.'
        else # perform registration
          req.irons.register username, password, (err, user) ->
            return next(err) if err
            req.login user, (err) ->
              return next(err) if err
              res.send JSON.stringify
                userId: user.get('id')
                toast:
                  type: 'success'
                  msg: 'Registered!'

