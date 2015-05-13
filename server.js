#!/bin/env node
var fs = require('fs');
var sass = require('node-sass');
var OtterOrNotter = require('./OtterOrNotter.js');


/* Handle Termination */
(function() {
	var terminate = function(sig) {
		console.log('%s: Received %s - terminating ...', Date(Date.now()), sig);
		process.exit(1);
	}

	process.on('exit', function() {
		console.log('%s: Node server stopped.', Date(Date.now()) );
	});

	['SIGHUP', 'SIGINT', 'SIGQUIT', 'SIGILL', 'SIGTRAP', 'SIGABRT',
	 'SIGBUS', 'SIGFPE', 'SIGUSR1', 'SIGSEGV', 'SIGUSR2', 'SIGTERM'
	].forEach(function(element, index, array) {
		process.on(element, terminate.bind(element));
	});
})();

/* Render SCSS */
sass.render({file: 'static/style.scss', outFile: 'static/style.css'}, function(err, result) {
	fs.writeFile('static/style.css', result.css);
})

/* Start Server */
// new OtterOrNotter();
