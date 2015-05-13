class OtterOrNotterFrontend
	constructor: (@parent, @otterButton, @notterButton) ->
		@infoDuration = 500
		@transitionDuration = 300

		@loading true
		@fetchFirstImage()

		@otterButton.addEventListener 'click', =>
			@rate 'otter'
		@notterButton.addEventListener 'click', =>
			@rate 'notter'

	createLoader: ->
		loader = document.createElement 'div'
		@parent.appendChild loader

	createImage: (item) ->
		if !@imageContainer
			@imageContainer = document.createElement 'div'
			@imageContainer.className = 'image__item'
			@parent.appendChild @imageContainer

		img = document.createElement 'img'
		img.src = 'http://res.cloudinary.com/scriptist/image/upload/c_fill,h_375,w_500,q_75/' + item.image.public_id
		@imageContainer.appendChild img
		@currentImageElm = img

		img.addEventListener 'load', =>
			@loading false

	createInfo: (item) ->
		info = document.createElement 'div'
		info.className = 'image__overlay image__overlay--hidden-start'
		@parent.appendChild info
		document.body.offsetHeight # Repaint
		info.className = 'image__overlay'

		otterRating = parseInt 100 * item.rating.otter / (item.rating.otter + item.rating.notter)
		notterRating = 100 - otterRating

		otterColumn  = document.createElement 'div'
		notterColumn = document.createElement 'div'
		otterColumn.className = 'column column--otter'
		notterColumn.className = 'column column--notter'
		otterColumn.style.height = "#{otterRating}%"
		notterColumn.style.height = "#{notterRating}%"
		otterColumn.setAttribute 'data-percent', otterRating
		notterColumn.setAttribute 'data-percent', notterRating
		info.appendChild otterColumn
		info.appendChild notterColumn

		setTimeout ->
			info.className += ' image__overlay--hidden-end'
		, @infoDuration + @transitionDuration

		setTimeout =>
			@parent.removeChild info
			@otterButton.removeAttribute 'disabled'
			@notterButton.removeAttribute 'disabled'
		, @infoDuration + @transitionDuration * 2

		@otterButton.setAttribute 'disabled', 'disabled'
		@notterButton.setAttribute 'disabled', 'disabled'

	onItemLoad: (item) =>
		@currentImage = item
		@createImage item

	loading: (value) ->
		if typeof value == 'boolean' && value != @isLoading
			@isLoading = value

			if !@loader
				@loader = @createLoader()

			if @isLoading
				@loader.className = 'image__loading'
			else
				@loader.className = 'image__loading is-hidden'

		@isLoading

	rate: (rating) ->
		data = {
			id: @currentImage.image.public_id
			rating: rating
		}

		@currentImage.rating[rating]++
		@createInfo @currentImage

		currentImageElm = @currentImageElm
		setTimeout =>
			@imageContainer.removeChild currentImageElm
		, @transitionDuration

		@fetchJSON '/api/rate', data, @onItemLoad

	fetchFirstImage: ->
		# TODO: Send ?first=true if this is the user's first time on the page
		@fetchJSON '/api/random', null, @onItemLoad

	fetchJSON: (url, content, callback) ->
		xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange = ->
			if xmlhttp.readyState == XMLHttpRequest.DONE
				if xmlhttp.status == 200
					callback JSON.parse xmlhttp.responseText
				else
					alert 'An error has occurred - please try again later'
		if content
			xmlhttp.open 'POST', url, true
			xmlhttp.setRequestHeader("Content-type", "application/json");
			xmlhttp.send JSON.stringify content
		else
			xmlhttp.open 'GET', url, true
			xmlhttp.send()



new OtterOrNotterFrontend(
	document.querySelector('.image'),
	document.querySelector('.cta__otter'),
	document.querySelector('.cta__notter')
)