var express = require('express');

module.exports = function() {
	var self = this;

	self.init = function() {
		self.getEnvironmentVariables();
		self.serve();
	}

	self.getEnvironmentVariables = function() {
		self.ipaddress = process.env.OPENSHIFT_NODEJS_IP;
		self.port      = process.env.OPENSHIFT_NODEJS_PORT || 8080;

		if (typeof self.ipaddress === "undefined") {
			//  Log errors on OpenShift but continue w/ 127.0.0.1 - this
			//  allows us to run/test the app locally.
			console.warn('No OPENSHIFT_NODEJS_IP var, using 127.0.0.1');
			self.ipaddress = "127.0.0.1";
		};
	}

	self.serve = function() {
		self.app = express();

		self.app.use(express.static('static'));

		self.server = self.app.listen(self.port, self.ipaddress, function () {
			console.log('%s: Node server started on %s:%d ...',
						Date(Date.now() ), self.ipaddress, self.port);
		});
	}


	self.init();
}