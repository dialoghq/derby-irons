credential  = require('credential')

module.exports = (options) ->
  ironsModel = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use racer.modelMiddleware() before ironsModel()')
    unless req.session?.id?
      throw new Error('use publishId() before model()')

    model = req.getModel()

    req.irons =
      getSession: () ->
        model.at('irons_sessions.' + req.session.id)

      fetchSession: (done) ->
        session = req.irons.getSession()
        model.fetch session, (err) ->
          done(err, session)
          model.unfetch session

      getUser: (id) ->
        model.at("irons_users.#{id}")

      fetchUser: (id, done) ->
        id ||= model.id()
        user = req.irons.getUser(id)
        model.fetch user, (err) ->
          unless err?
            user.setNull('id', id)
            user.setNull('sessions', [])
            user.setNull('emails', [])
          done(err, user)
          model.unfetch user

      fetchUserByEmail: (email, done) ->
        users = model.query 'irons_users',
          emails: email.toLowerCase()
          $limit: 1
        model.fetch users, (err) ->
          id = users?.fetchIds?[0]?[0]
          if id?
            req.irons.fetchUser id, (err, user) ->
              done(err, user)
          else
            done()
          model.unfetch users

      setPassword: (user, password, done) ->
        credential.hash password, (err, hash) ->
          return done(err) if err
          user.set('password', hash)
          done(null, user)

      checkPassword: (user, password, done) ->
        unless user?.password or user?.get('password')
          return done(new Error 'No password set for this user.')
        credential.verify (user.password || user.get 'password'), password, (err, isValid) ->
          done(err, isValid)

      registerLocal: (email, password, done) ->
        req.irons.fetchUser null, (err, user) ->
          return done(err) if err
          user.push('sessions', req.session.id)
          user.push('emails', email.toLowerCase())
          req.irons.setPassword user, password, (err, user) ->
            done(err, user)

    next()

