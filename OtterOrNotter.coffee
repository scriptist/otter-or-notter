cloudinary = require 'cloudinary'
express = require 'express'

module.exports = class OtterOrNotter
	constructor: ->
		@getEnvironmentVariables()
		@getRatings()
		@initializeCloudinary()
		@fetchImageList @serve

	initializeCloudinary: ->
		cloudinary.config {
			cloud_name: @cloudinary.name
			api_key: @cloudinary.key
			api_secret: @cloudinary.secret
		}

	fetchImageList: (callback) ->
		cloudinary.api.resources (response) =>
			@images = response.resources
			callback.call(@)
		, {type: 'upload', prefix: 'otterornotter.com/'}

	getEnvironmentVariables: ->
		@ipaddress = process.env.OPENSHIFT_NODEJS_IP
		@port      = process.env.OPENSHIFT_NODEJS_PORT || 8080
		@cloudinary =
			name:   process.env.CLOUDINARY_NAME
			key:    process.env.CLOUDINARY_KEY
			secret: process.env.CLOUDINARY_SECRET

		if typeof @ipaddress == "undefined"
			# Log errors on OpenShift but continue w/ 127.0.0.1 - this
			# allows us to run/test the app locally.
			console.warn 'No OPENSHIFT_NODEJS_IP var, using 127.0.0.1'
			@ipaddress = "127.0.0.1"

	getRatings: ->
		@ratings = {}

	serve: ->
		@app = express()
		@app.use express.static 'static'

		@app.get '/api/random', (req, res) =>
			res.send @randomImage()

		@server = @app.listen @port, @ipaddress, =>
			console.log '%s: Node server started on %s:%d ...', Date(Date.now()), @ipaddress, @port

	randomImage: ->
		i = Math.floor(Math.random() * @images.length)
		image = @images[i]

		if image.public_id not of @ratings
			@ratings[image.public_id] = {otter: 0, notter: 0}

		{image: image, rating: @ratings[image.public_id]}
