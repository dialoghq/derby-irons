// Generated by CoffeeScript 1.6.3
(function() {
  module.exports = function(options) {
    var sessionId;
    return sessionId = function(req, res, next) {
      var model, _base;
      if (!((req.getModel != null) && typeof req.getModel === typeof Function)) {
        throw new Error('use store.modelMiddleware() before sessionId()');
      }
      model = req.getModel();
      (_base = req.session).id || (_base.id = model.id());
      return next();
    };
  };

}).call(this);