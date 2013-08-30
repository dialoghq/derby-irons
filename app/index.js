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
      form.set('nonce', model.id());
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
      form.set('nonce', model.id());
      model.ref('_page.irons.forms.login', form);
      page.render('register');
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
    var model = app.model;
    var form = model.at(el); if (!form) { return false; }
    var path = model.at(el).path();
    if ( !valid(form, schema) ) {
      if (model.toast) { model.toast('error', 'Please fix the errors and try again.'); }
      return false;
    }
    var xhr = model.get(path + '.xhr');
    if (xhr) {
      model.del(path + '.xhr');
      if (model.toast) { model.toast('warning', 'Action cancelled.'); }
      xhr.abort();
    } else {
      xhr = new XMLHttpRequest();
      model.set(path + '.xhr', xhr);
      xhr.open(el.method, el.action, true);
      xhr.onreadystatechange = function() {
        if (this.readyState === 4) {
          var type = 'error';
          if (this.status === 200) { type = 'success'; }
          if (model.toast) { model.toast(type, this.responseText); }
          model.del(path + '.xhr');
        }
      };
      xhr.ontimeout = function(e) {
        model.del(path + '.xhr');
        if (model.toast) {
          return model.toast('error', 'Action timed out.');
        }
      };
      return xhr.send(new FormData(el));
    }
  });

  return app.createLibrary(config, options);
};

