var basicAuth = require("basic-auth");

module.exports.auth = function (req, res, next) {
	function unauthorized(res) {
		res.set("WWW-Authenticate", "Basic realm=Authorization Required");
		return res.status(401).end();
	}

	var user = basicAuth(req);

	if (!user || !user.name || !user.pass) {
		return unauthorized(res);
	}

	if (user.name == "Sam" && user.pass == "DuckTape") {
		return next();
	} else {
		return unauthorized(res);
	}
};

module.exports.noCache = function (req, res, next) {
	res.header("Cache-Control", "no-cache, no-store, must-revalidate");
	res.header("Pragma", "no-cache");
	res.header("Expires", 0);
	next();
};
