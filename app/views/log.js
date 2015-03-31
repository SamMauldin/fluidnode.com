var base = require("../server/base")();

var logger = require("../server/log")("online-log");

base.app.get("/", function(req, res) {
	res.send("You have reached the logging endpoint. Please use the API instead.");
});

base.app.get("/log", function(req, res) {
	if (req.param("msg")) {
		res.send("Success!");
		logger.log(req.param("msg"));
	} else {
		res.send("Bad request");
	}
});

base.listen(8014);
