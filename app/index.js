var valid = require('../lib/valid');

var config = {
  ns: 'derby-irons',
  filename: __filename
};

var schema = {
  username: 'email',
  password: 'password'
};

module.exports = function(app, options) {

  app.get('/register', function(page, model, params, next) {
    sessionId = model.get('_irons.sessionId');
    session = model.at('irons_sessions.'+sessionId);
    model.subscribe(session, function(err){
      if (err) { return next(err); }
      form = session.at('forms.register');
      model.ref('_page.irons.forms.register', form);
      page.render('register');
    });
  });

  app.get('/login', function(page, model, params, next) {
    sessionId = model.get('_irons.sessionId');
    session = model.at('irons_sessions.'+sessionId);
    model.subscribe(session, function(err){
      if (err) { return next(err); }
      form = session.at('forms.login');
      model.ref('_page.irons.forms.login', form);
      page.render('login');
    });
  });

  app.fn('irons.focus', function(e, el) {
    if (!el.id || !app.model.at(el)) { return false; }
    var path = app.model.at(el).path();
    app.model.set(path + "." + el.id + ".focused", true);
    return true;
  });

  app.fn('irons.blur', function(e, el) {
    if (!el.id || !app.model.at(el)) { return false; }
    var path = app.model.at(el).path();
    app.model.del(path + "." + el.id + ".focused");
    return true;
  });

  app.fn('irons.reveal', function(e, el) {
    if (!el.id || !app.model.at(el)) { return false; }
    var path = app.model.at(el).path();
    var reveal = path + "." + el.id + ".revealed";
    if (el.checked === true) {
      app.model.set(reveal, true);
    } else {
      app.model.del(reveal);
    }
    return true;
  });

  app.fn('irons.submit', function(e, el) {
    if (!el || !el.id) { return false; }
    var model = app.model;
    var form = model.at(el);
    var path = form.path();
    var validate = path.match(/irons\.forms\.(register|login)/);
    if ( validate && !valid(form, schema) ) {
      if (model.toast) { model.toast('error', 'Please fix the errors and try again.'); }
      return false;
    }
    var xhr = model.get('_irons.xhr.' + el.id);
    if (xhr) {
      model.del('_irons.xhr.' + el.id);
      if (model.toast) { model.toast('warning', 'Action cancelled.'); }
      // xhr.abort(); TODO figure out how to actually do this
    } else {
      xhr = new XMLHttpRequest();
      model.set('_irons.xhr.' + el.id, xhr);
      xhr.open(el.method, el.action, true);
      xhr.onreadystatechange = function() {
        if (this.readyState === 4) {
          try {
            var res = JSON.parse(this.responseText);
            if (res && res.userId !== undefined) {
              if (res.userId === false) {
                model.del('_irons.userId');
              } else {
                model.set('_irons.userId', res.userId);
              }
            }
            if (model.toast && res && res.toast) { model.toast(res.toast.type, res.toast.msg); }
          } catch (err) {
            console.log(this.responseText);
            if (model.toast) { model.toast('error', 'Could not parse response.'); }
          }
          model.del('_irons.xhr.' + el.id);
        }
      };
      xhr.ontimeout = function(e) {
        if (model.toast) { return model.toast('error', 'Action timed out.'); }
        model.del('_irons.xhr.' + el.id);
      };
      return xhr.send(new FormData(el));
    }
  });

  return app.createLibrary(config, options);
};

