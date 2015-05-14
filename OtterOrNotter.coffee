cloudinary = require 'cloudinary'
express    = require 'express'
mongo      = require 'mongodb'

module.exports = class OtterOrNotter
	constructor: ->
		@getEnvironmentVariables()
		@loadData =>
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
		, {type: 'upload', prefix: 'otterornotter.com/', max_results: 100, tags: true}

	getEnvironmentVariables: ->
		@ipaddress = process.env.OPENSHIFT_NODEJS_IP
		@port      = process.env.OPENSHIFT_NODEJS_PORT || 8080
		@cloudinary =
			name       : process.env.CLOUDINARY_NAME
			key        : process.env.CLOUDINARY_KEY
			secret     : process.env.CLOUDINARY_SECRET
		@mongodb =
			url        : process.env.OPENSHIFT_MONGODB_DB_URL
			collection : 'collection'
			name       : 'name'

		if typeof @ipaddress == "undefined"
			# Log errors on OpenShift but continue w/ 127.0.0.1 - this
			# allows us to run/test the app locally.
			console.warn 'No OPENSHIFT_NODEJS_IP var, using 127.0.0.1'
			@ipaddress = "127.0.0.1"

	serve: ->
		@app = express()
		@app.use express.json()
		@app.use express.static 'static'

		@app.get '/api/random', (req, res) =>
			res.send @randomImage(req.query.first)

		@app.post '/api/rate', (req, res) =>
			data   = req.body
			id     = data.id
			rating = data.rating

			if (id of @ratings) && (rating == 'otter') || (rating == 'notter')
				@ratings[id][rating]++
				console.log "#{Date(Date.now())}: Rated #{id} #{rating}"
				@saveData()

			res.send @randomImage()

		@server = @app.listen @port, @ipaddress, =>
			console.log "#{Date(Date.now())}: Node server started on #{@ipaddress}:#{@port} ..."

	randomImage: (forceOtter) ->
		while !image || (forceOtter && 'otter' not in image.tags)
			i = Math.floor(Math.random() * @images.length)
			image = @images[i]

		if image.public_id not of @ratings
			@ratings[image.public_id] = {otter: Math.floor(Math.random() * 3), notter: Math.floor(Math.random() * 3)}

		{image: image, rating: @ratings[image.public_id]}

	saveData: ->
		mongo.MongoClient.connect @mongodb.url, (err, db) ->
			db.collection(@mongodb.collection).update(
				# Condition
				{
					name: @mongodb.name
				},
				# Operation
				{
					$set: {
						name: @mongodb.name
						ratings: @ratings
					}
				},
				# Options
				{
					safe: true
					upsert: true
				},
				(err) ->
					if err
						console.log "#{Date(Date.now())}: Error saving to DB: #{err}"
					else
						console.log "#{Date(Date.now())}: Saved successfully"
			)
	loadData: (callback) ->
		mongo.MongoClient.connect @mongodb.url, (err, db) =>
			db.collection(@mongodb.collection).find({name: @mongodb.name}).limit(1).toArray (err, docs) =>
				if docs.length == 0
					return @ratings = {}

				@ratings = docs[0].ratings

				typeof callback == 'function' && callback()