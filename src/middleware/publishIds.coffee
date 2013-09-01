module.exports = (options) ->
  publishIds = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use store.modelMiddleware() before publishIds()')
    unless req.session?.id?
      throw new Error('use sessionId() before publishIds()')
    model = req.getModel()
    model.set '_irons.sessionId', req.session.id
    model.set '_irons.userId', req.user.get('id') if req.user?
    next()


