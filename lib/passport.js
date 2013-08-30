// Generated by CoffeeScript 1.6.3
(function() {
  var LocalStrategy, passport;

  passport = require('passport');

  LocalStrategy = require('passport-local').Strategy;

  module.exports = function(config) {
    passport.use(new LocalStrategy(config.get('passport'), function(req, email, password, done) {
      return req.irons.fetchUserByEmail(email, function(err, user) {
        if (err) {
          return done(err);
        }
        if (!user) {
          return done(new Error('User does not exist'));
        }
        return req.irons.checkPassword(user, password, function(err, isValid) {
          if (isValid) {
            if (user) {
              user.push('sessions', req.session.id);
            }
            return done(err, user);
          } else {
            return done(err, false);
          }
        });
      });
    }));
    return passport;
  };

}).call(this);