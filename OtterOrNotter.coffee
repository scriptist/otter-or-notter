express = require 'express'

module.exports = class OtterOrNotter
	constructor: ->
 		@getEnvironmentVariables()
 		@serve()
	getEnvironmentVariables: ->
		@ipaddress = process.env.OPENSHIFT_NODEJS_IP
		@port      = process.env.OPENSHIFT_NODEJS_PORT || 8080

		if typeof @ipaddress == "undefined"
			# Log errors on OpenShift but continue w/ 127.0.0.1 - this
			# allows us to run/test the app locally.
			console.warn 'No OPENSHIFT_NODEJS_IP var, using 127.0.0.1'
			@ipaddress = "127.0.0.1"

	serve: ->
		@app = express()
		@app.use express.static 'static'

		@server = @app.listen @port, @ipaddress, ->
			console.log '%s: Node server started on %s:%d ...', Date(Date.now()), @ipaddress, @port