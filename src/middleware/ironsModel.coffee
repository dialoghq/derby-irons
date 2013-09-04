Lazy = require('lazy.js')
credential  = require('credential')

pushOnce = (doc, field, val) ->
  unless doc?.get? and Lazy(doc.get field).any((v) -> v is val)
    doc.push(field, val)

module.exports = (options) ->
  ironsModel = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use racer.modelMiddleware() before ironsModel()')
    unless req.session?.id?
      throw new Error('use publishId() before model()')

    model = req.getModel()

    req.irons =
      getSession: getSession = () ->
        model.at('irons_sessions.' + req.session.id)

      fetchSession: fetchSession = (done) ->
        session = getSession()
        model.fetch session, (err) ->
          done(err, session)
          model.unfetch session

      getUser: getUser = (id) ->
        model.at("irons_users.#{id}")

      newUser: newUser = (email, done) ->
        id = model.id()
        model.add 'irons_users',
          id: id
          sessions: [req.session.id]
          emails: [email]
          , (err) ->
            done(err, id)

      fetchUser: fetchUser = (id, done) ->
        user = getUser(id)
        model.fetch user, (err) ->
          done(err, user)
          model.unfetch user

      fetchUserByEmail: fetchUserByEmail = (email, done) ->
        users = model.query 'irons_users',
          emails: email.toLowerCase()
          $limit: 1
        model.fetch users, (err) ->
          id = users?.fetchIds?[0]?[0]
          if id?
            fetchUser id, (err, user) ->
              done(err, user)
          else
            done()
          model.unfetch users

      setPassword: setPassword = (user, password, done) ->
        credential.hash password, (err, hash) ->
          return done(err) if err
          user.set('password', hash)
          done(null, user)

      checkPassword: checkPassword = (user, password, done) ->
        unless user?.password or user?.get('password')
          return done(new Error 'No password set for this user.')
        credential.verify (user.password || user.get 'password'), password, (err, isValid) ->
          done(err, isValid)

      sessionAttach: sessionAttach = (user) ->
        pushOnce(user, 'sessions', req.session.id)

      register: register = (email, password, done) ->
        newUser email, (err, id) ->
          return done(err) if err
          fetchUser id, (err, user) ->
            return done(err) if err
            setPassword user, password, (err, user) ->
              done(err, user)

    next()

