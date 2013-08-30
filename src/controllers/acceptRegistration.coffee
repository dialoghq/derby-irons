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

    model = req.getModel()
    session = req.irons.getSession()
    userQuery = model.query('irons_users', {emails: username, $limit: 1})
    model.fetch session, userQuery, (err) ->
      return next(err) if err

      # perform validation
      form = session.at('forms.register')
      form.set('username.input', username)
      form.set('password.input', password) # security risk?
      unless valid(form, registrationSchema)
        return res.send 422, 'Please fix the errors and try again.'

      if existingUser = userQuery.get()?[0]
        # handle pre-existing registration
        credential.verify existingUser.password, password, (err, isValid) ->
          return next(err) if err
          if isValid
            req.login existingUser, (err) ->
              return next(err) if err
              res.send 'Logged in! (Already registered.)'
          else
            res.send 401, 'Already registered. Please check your email to continue.'
      else
        # perform registration
        credential.hash password, (err, hash) ->
          return next(err) if err
          userId = model.id()
          user = model.at("irons_users.#{userId}")
          user.fetch (err) ->
            return next(err) if err
            user.set
              sessionIds: [req.session.id]
              emails:     [username]
              password:   hash
            , (err) ->
              return next(err) if err
              req.login user, (err) ->
                res.send 'Registered!'

