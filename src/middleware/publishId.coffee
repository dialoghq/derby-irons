module.exports = (options) ->
  publishId = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use store.modelMiddleware() before publishIds()')
    model = req.getModel()
    req.session.id ||= model.id()
    model.set '_irons.sessionId', req.session.id
    next()

