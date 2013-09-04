passport = require('passport')
LocalStrategy = require('passport-local').Strategy

module.exports = (config) ->
  passport.use new LocalStrategy config.get('passport'), (req, email, password, done) ->
    req.irons.fetchUserByEmail email, (err, user) ->
      return done(err) if err
      return done(null, false, 'Email not registered') unless user
      req.irons.checkPassword user, password, (err, isValid) ->
        if isValid
          req.irons.sessionAttach(user)
          done(err, user)
        else
          done(err, false, 'Incorrect password.')

  passport

