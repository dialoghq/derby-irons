passport = require('passport')

module.exports = (options) ->
  login = (req, res, next) ->
    options.load(passport: failureRedirect: req.get('Referer'))
    passport.authenticate('local', options.get('passport'), (err, user, info) ->
      return next(err) if err
      return res.send 401, 'Authentication failure, please try again.' unless user
      req.login user, (err) ->
        return next(err) if err
        res.send 200, 'Logged in.'
    )(req, res, next)

