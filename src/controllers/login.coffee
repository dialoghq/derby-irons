passport = require('passport')

module.exports = (options) ->
  login = (req, res, next) ->
    options.load(passport: failureRedirect: req.get('Referer'))
    passport.authenticate('local', options.get('passport'), (err, user, info) ->
      console.log "err: #{err}, user: #{user}, info: #{info}"
      return next(err) if err
      if user
        req.login user, (err) ->
          return next(err) if err
          res.send 200, JSON.stringify
            userId: user.get('id')
            toast:
              type: 'success'
              msg: 'Logged in.'
      else
        # TODO add message directly to field
        res.send 401, JSON.stringify
          userId: null
          toast:
            type: 'error'
            msg: info
    )(req, res, next)

