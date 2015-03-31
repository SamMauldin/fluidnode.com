var base = require("../server/base")();
var uuidgen = require("node-uuid");

var clients = {};

base.app.all("/", function(req, res) {
	res.send("You have reached the EnderNet Endpoint. Please use the API instead.");
});

base.app.all("/start", function(req, res) {
	if (req.param("channel")) {
		var chan = req.param("channel");
		var uuid = uuidgen();
		var name = uuidgen();
		clients[uuid] = {
			messages : [],
			channel : chan,
			name : name
		};
		res.send(JSON.stringify({
			uuid: uuid,
			name: name
		}));
	} else {
		res.send(JSON.stringify({
			err : "No channel specified"
		}));
	}
});

base.app.all("/send", function(req, res) {
	if (req.param("uuid") && req.param("message")) {
		var uuid = req.param("uuid");
		var msg = req.param("message");
		if (clients[uuid]) {
			for (var v in clients) {
				if (clients[v].channel == clients[uuid].channel) {
					clients[v].messages.push([msg, clients[uuid].name]);
				}
			}
			res.send(JSON.stringify({
				res : true
			}));
		} else {
			res.send(JSON.stringify({
				err : "No such uuid"
			}));
		}
	} else {
		res.send(JSON.stringify({
			err : "No channel/uuid specified"
		}));
	}
});

base.app.all("/poll", function(req, res) {
	if (req.param("uuid")) {
		var uuid = req.param("uuid");
		if (clients[uuid]) {
			if (clients[uuid].messages.length > 0) {
				var msg = clients[uuid].messages.shift();
				res.send(JSON.stringify({
					res : msg[0],
					from : msg[1]
				}));
			} else {
				res.send(JSON.stringify({
					res : false
				}));
			}
		} else {
			res.send(JSON.stringify({
				err : "No such uuid"
			}));
		}
	} else {
		res.send(JSON.stringify({
			err : "No uuid specified"
		}));
	}
});

base.app.all("/check", function(req, res) {
	if (req.param("uuid")) {
		if (clients[req.param("uuid")]) {
			res.send("true");
		} else {
			res.send("false");
		}
	} else {
		res.send("false");
	}
});

base.app.use("/admin/", require("../server/middleware").auth);

base.app.get("/admin/list", function(req, res) {
	res.send(JSON.stringify(clients));
});

base.listen(8011);
