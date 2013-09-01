module.exports = (options) ->
  sessionId = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use store.modelMiddleware() before sessionId()')
    model = req.getModel()
    req.session.id ||= model.id()
    next()

