module.exports = (options) ->
  logout = (req, res, next) ->
    req.logout()
    res.send 200, JSON.stringify
      userId: false
      toast:
        type: 'success'
        msg: 'Logged out.'

