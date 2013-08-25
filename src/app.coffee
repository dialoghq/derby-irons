valid = require('./valid')

config =
  ns: 'derby-irons'
  filename: __filename

schema =
  username: 'email'
  password: 'password'

module.exports = (app, options) ->

  app.fn 'irons.focus', (e, el) ->
    return false unless el.id?
    app.model.set("_page.irons.#{el.id}.focused", true)

  app.fn 'irons.blur', (e, el) ->
    return false unless el.id?
    app.model.del("_page.irons.#{el.id}.focused")

  app.fn 'irons.reveal', (e, el) ->
    return false unless el.id?
    path = "_page.irons.#{el.id}.revealed"
    if el.checked is true
      app.model.set(path, true)
    else
      app.model.del(path)

  app.fn 'irons.submit', (e, el) ->
    model = app.model
    return false unless model?.at(el)?.path() is '_page.irons'
    unless valid(model.at(el), schema)
      model.toast('error', 'Please fix the errors and try again.') if model.toast?
      return false
    if (xhr = model.get '_page.irons.xhr')
      xhr.abort()
      model.del('_page.irons.xhr')
      model.toast('warning', 'Action cancelled.') if model.toast?
    else
      xhr = new XMLHttpRequest()
      model.set('_page.irons.xhr', xhr)
      xhr.open(el.method, el.action, true)
      xhr.onload = (e) ->
        model.del('_page.irons.xhr')
        model.toast('success', 'Action completed!') if model.toast?
        # TODO: toast success/failure based on status code
        # TODO: follow redirect based on status code
      xhr.ontimeout = (e) ->
        model.del('_page.irons.xhr')
        model.toast('error', 'Action timed out.') if model.toast?
      xhr.send new FormData(el)

  app.createLibrary(config, options)

