passport = require('passport')

module.exports = (options) ->
  passportSerializers = (req, res, next) ->
    unless req.irons?.getUser? and typeof req.irons.getUser is typeof Function
      throw new Error('use model() before passportSerializers()')

    passport.serializeUser (user, done) ->
      done null, (user.id || user.get 'id')

    passport.deserializeUser (id, done) ->
      return done(new Error 'User ID missing') unless id
      user = req.irons.getUser(id)
      user.fetch (err) ->
        return done(err) if err
        done(null, user)

    next()

