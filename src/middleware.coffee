express     = require('express')
expressApp  = express()

module.exports = (options, model) ->
  config = require('./defaults')
  if options
    config.load(options)
    config.validate()

  passport = require('./passport')(config)

  expressApp
    # Parse form data
    .use( express.bodyParser() )
    .use( express.methodOverride() )

    # Session middleware
    .use( express.cookieParser() )
    .use( express.cookieSession
      key:    'irons.id'
      secret: config.get('session.secret')
    )

    # Generate a Derby-compatible id for the session
    .use( require('./middleware/sessionId')() )

    # Make the scoped models available at req.irons
    .use( require('./middleware/ironsModel')() )

    .use( require('./middleware/passportSerializers')() )
    .use( passport.initialize() )
    .use( passport.session() )

    # Make sessionId and userId available to Derby
    .use( require('./middleware/publishIds')() )

    # Allow email-based registrations
    .post( '/register', require('./controllers/register')(config) )
    .post( '/login', require('./controllers/login')(config) )
    .post( '/logout', require('./controllers/logout')(config) )

