passport = require('passport')
LocalStrategy = require('passport-local').Strategy

module.exports = (config) ->
  passport.use new LocalStrategy config.get('passport'), (req, email, password, done) ->
    req.irons.fetchUserByEmail email, (err, user) ->
      return done(err) if err
      return done(new Error 'User does not exist') unless user
      req.irons.checkPassword user, password, (err, isValid) ->
        if isValid
          user.push('sessions', req.session.id) if user
          done(err, user)
        else
          done(err, false)

  passport

