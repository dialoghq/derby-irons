passport = require('passport')

module.exports = (options) ->
  passportSerializers = (req, res, next) ->
    unless req.irons?.fetchUser?
      throw new Error('use ironsModel() before passportSerializers()')

    passport.serializeUser (user, done) ->
      done null, user.get('id')

    passport.deserializeUser (id, done) ->
      return done(new Error 'User ID missing') unless id
      req.irons.fetchUser id, (err, user) ->
        done(err, user)

    next()

