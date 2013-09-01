module.exports = (options) ->
  logout = (req, res, next) ->
    req.logout()
    res.send(200, 'Logged out.')

