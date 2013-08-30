passport    = require('passport')
express     = require('express')
expressApp  = express()

module.exports = (options, model) ->
  config = require('./defaults')
  if options
    config.load(options)
    config.validate()

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

    # Make Irons token available to Derby
    .use( require('./middleware/publishId')() )

    # Make the scoped Irons models available at req.irons
    .use( require('./middleware/model')() )

    .use( require('./middleware/passportSerializers')() )
    .use( passport.initialize() )
    .use( passport.session() )

    # Allow email-based registrations
    .post( '/register', require('./controllers/acceptRegistration')(options) )

