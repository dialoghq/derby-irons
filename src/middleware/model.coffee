module.exports = (options) ->
  model = (req, res, next) ->
    unless req.getModel? and typeof req.getModel is typeof Function
      throw new Error('use racer.modelMiddleware() before model()')
    unless req.session?.id?
      throw new Error('use publishId() before model()')

    getSession = () ->
      req.getModel().at('irons_sessions.' + req.session.id)

    getUser = (id) ->
      req.getModel().at('irons_users.' + id)

    req.irons =
      getSession: getSession
      getUser:    getUser

    next()

