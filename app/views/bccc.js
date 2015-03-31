var log = require("../server/log")("bccc-couples");
var cfg = require("./cfg");
var db = require("../server/db");
var uuid = require("node-uuid");

var Couple = db.models.couple;
var Tournament = db.models.tournament;

function importData(json) {
	json.results.forEach(function(v) {
		var couple = new Couple();

		couple.email = v.email;
		couple.email2 = v.email2;
		couple.name = v.name;
		couple.coupleId = v.objectId;

		couple.save();
	});
}

function initData() {
	var query = Tournament.findOne({ "only" : true });
	query.exec(function (err, tournament) {
		if (err) {
			log.err("Initializing data: " + err);
			return;
		} else if (!tournament) {
			var tourn = new Tournament();

			tourn.only = true;
			tourn.stage = 3;

			tourn.save();
		}
	});
}

initData();

function getTournament(cb) {
	var query = Tournament.findOne({ "only" : true });
	query.exec(function (err, tournament) {
		if (err || !tournament) {
			cb(err || true);
			return;
		}
		cb(null, tournament);
	});
}

function getCouple(id, cb) {
	var query = Couple.findOne({ coupleId: id });
	query.exec(function(err, couple) {
		if (err || !couple) {
			cb(err || true);
			return;
		}
		cb(null, couple);
	});
}

function getCouples(cb) {
	var query = Couple.find();
	query.exec(function(err, couples) {
		if (err || !couples) {
			cb(err || true);
			return;
		}
		cb(null, couples);
	});
}

function resetCouple(id, cb) {
	getCouple(id, function(err, couple) {
		if (err || !couple) {
			cb(true);
			return;
		}
		couple.step = null;
		couple.eating = null;
		couple.substitute = null;
		couple.playing = null;
		couple.comments = null;
		couple.done = null;
		couple.save(function (err) {
			cb(err);
		});
	});
}

var nodemailer = require("nodemailer");

var mailtransport = nodemailer.createTransport({
	host: "mail.fluidnode.com",
	requireTLS: true,
	auth: {
		user: "BerryCreekCouples@fluidleague.com",
		pass: "6gzughRUXd7im3c22G43vNf6F8nG9t"
	}
});

var base = require("../server/base")();

var bodyParser = require("body-parser");

base.app.use(bodyParser.json());
base.app.use(bodyParser.urlencoded({ extended: true }));
base.app.use(require("../server/middleware").noCache);

base.app.use(base.express.static("app/pages/bccc"));

base.app.get("/c/cpleague/s.html", function(req, res) {
	if (req.param("id")) {
		getTournament(function(err, t) {
			getCouple(req.param("id"), function(err, couple) {
				if (err || couple === null) {
					res.redirect("/errpage.html");
					return;
				}
				res.render("../app/pages/bccc/c/cpleague/s.ejs", {
					couple: couple,
					tourn: t
				});
			});
		});
	} else {
		res.redirect("/");
	}
});

base.app.post("/c/cpleague/submit/:id", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || couple === null) {
				res.redirect("/errpage.html");
				return;
			}

			couple.agent = req.headers["user-agent"];

			var playing = req.body.playing && req.body.playing == "yes";
			var eating = req.body.eating && req.body.eating == "yes";

			var subname = req.body.subname;

			var comments = req.body.comments;

			couple.playing = playing;
			couple.eating = eating;

			couple.substitute = subname;

			couple.comments = comments;

			couple.step = 2;

			couple.done = true;

			couple.save(function (err) {
				if (err) {
					res.redirect("/errpage.html");
					return;
				}
				log.log(req.param("id") + " has registed for the playday");
				res.redirect("/c/cpleague/s.html?id=" + req.param("id"));
			});

		});
	} else {
		res.redirect("/");
	}
});

base.app.get("/c/cpleague/step2reset", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || couple === null) {
				res.redirect("/errpage.html");
				return;
			}
			couple.step = 3;
			couple.save(function (err) {
				if (err) {
					res.redirect("/errpage.html");
					return;
				}
				res.redirect("/c/cpleague/s.html?id=" + req.param("id"));
			});
		});
	} else {
		res.redirect("/");
	}
});

base.app.get("/c/cpleague/step3keep", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || couple === null) {
				res.redirect("/errpage.html");
				return;
			}
			couple.step = 2;
			couple.save(function (err) {
				if (err) {
					res.redirect("/errpage.html");
					return;
				}
				res.redirect("/c/cpleague/s.html?id=" + req.param("id"));
			});
		});
	} else {
		res.redirect("/");
	}
});

base.app.get("/c/cpleague/step3reset", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || couple === null) {
				res.redirect("/errpage.html");
				return;
			}

			couple.step = 1;
			couple.done = false;

			couple.save(function (err) {
				if (err) {
					res.redirect("/errpage.html");
					return;
				}
				log.log(req.param("id") + " has reset their data");
				res.redirect("/c/cpleague/s.html?id=" + req.param("id"));
			});
		});
	} else {
		res.redirect("/");
	}
});

// Admin Panel

base.app.use("/a/", require("../server/middleware").auth);

base.app.get("/a/cpleague/panel.html", function(req, res) {
	getTournament(function(err, t) {
		getCouples(function(err, couples) {
			if (err) {
				res.redirect("/errpage.html");
				return;
			}
			res.render("../app/pages/bccc/a/cpleague/panel.ejs", {
				couples: couples,
				tourn: t
			});
		});
	});
});

base.app.get("/a/cpleague/user.html", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || !couple) {
				res.redirect("/errpage.html");
				return;
			}
			res.render("../app/pages/bccc/a/cpleague/user.ejs", {
				couple: couple
			});
		});
	} else {
		res.redirect("/errpage.html");
	}
});

base.app.get("/p/cpleague/panel.html", function(req, res) {
	getCouples(function(err, couples) {
		if (err) {
			res.redirect("/errpage.html");
			return;
		}
		res.render("../app/pages/bccc/p/cpleague/panel.ejs", {
			couples: couples
		});
	});
});

base.app.get("/p/cpleague/members.html", function(req, res) {
	getCouples(function(err, couples) {
		if (err) {
			res.redirect("/errpage.html");
			return;
		}
		res.render("../app/pages/bccc/p/cpleague/members.ejs", {
			couples: couples
		});
	});
});

if (cfg.registration.enable) {

	base.app.post("/p/cpleague/register", function(req, res) {
		if (req.param("email") && req.param("fname") && req.param("fname2") && req.param("lname") && req.param("lname2")) {
			var newcouple = new Couple();
			newcouple.name = req.param("fname") + " " + req.param("lname") + " & " + req.param("fname2") + " " + req.param("lname2");
			newcouple.email = req.param("email");
			if (req.param("email") == req.param("email2")) {
				newcouple.email2 = "spam@fluidnode.com";
			} else {
				newcouple.email2 = req.param("email2") || "spam@fluidnode.com";
			}

			newcouple.coupleId = uuid();

			getTournament(function(err, t) {
				if (err) {
					// Ignore
				} else if (t.stage == 1 || t.stage == 2) {
					newcouple.step = 1;
					setTimeout(function() {
						var text = cfg.emailText.start;
						text = text.split("(names)").join(newcouple.name);
						text = text.split("(url)").join("https://bccc.fluidnode.com/c/cpleague/s.html?id=" + newcouple.coupleId);
						sendEmails(text, "Couples League Registration", newcouple.coupleId);
						log.log(req.param("id") + " has been sent a registration email");
					}, 1000 * 10);
				}

				log.log(req.param("id") + " has registered for this season");

				newcouple.save();
				res.redirect("/registered.html");
				return;
			});
		} else {
			res.redirect("/registererr.html");
			return;
		}
	});

	base.app.get("/whoisregistered.html", function(req, res) {
		getCouples(function(err, couples) {
			if (err) {
				res.redirect("/errpage.html");
				return;
			}
			couples.sort(function(a, b) {
				var atime = a.createdAt;
				var btime = b.createdAt;
				if (atime < btime) {
					return 1;
				} else {
					return 0;
				}
			});
			res.render("../app/pages/bccc/whoisregistered.ejs", {
				couples: couples
			});
		});
	});

}

base.app.post("/a/cpleague/sendmail", function(req, res) {
	log.log("Admin sending email");
	if (req.param("email") && req.param("subject")) {
		sendEmails(req.param("email").split("\n").join("<br>"), req.param("subject"));
		res.redirect("/a/cpleague/panel.html");
	} else {
		res.redirect("/errpage.html");
	}
});

base.app.post("/a/cpleague/start", function(req, res) {
	getTournament(function(err, t) {
		if (t.stage == 3) {
			t.stage = 0;
			t.save(function(err) {
				if (err) {
					res.redirect("/errpage.html");
					return;
				}
				log.log("Admin started tournament");
				res.redirect("/a/cpleague/panel.html");
			});
		} else {
			res.redirect("/a/cpleague/panel.html");
		}
	});
});

base.app.post("/a/cpleague/saveuser/:id", function(req, res) {
	if (req.param("id")) {
		getCouple(req.param("id"), function(err, couple) {
			if (err || !couple) {
				res.redirect("/errpage.html");
				return;
			}

			if (req.param("name")) {
				couple.name = req.param("name");
				couple.email = req.param("email") || "spam@fluidnode.com";
				couple.email2 = req.param("email2") || "spam@fluidnode.com";

				couple.save(function(err) {
					if (err) {
						res.redirect("/errpage.html");
						return;
					}
					log.log("Admin has modified user " + req.param("id"));
					res.redirect("/a/cpleague/panel.html");
				});

			} else {
				res.redirect("/errpage.html");
			}
		});
	} else {
		res.redirect("/errpage.html");
	}
});

base.app.post("/a/cpleague/tourn", function(req, res) {
	getTournament(function(err, t) {
		if (err) {
			res.redirect("/errpage.html");
			return;
		}
		t.arrive = req.param("arrive");
		t.day = req.param("day");
		t.format = req.param("format");
		t.time = req.param("time");
		t.details = req.param("details");
		t.menu = req.param("menu");
		t.save();
		setTimeout(function() {
			res.redirect("/a/cpleague/panel.html");
		}, 1000);
	});
});

function mailPerson(msg, sub, email) {
	var mailOptions = {
		from: "Berry Creek Couples <BerryCreekCouples@fluidleague.com>",
		to: "",
		subject: sub,
		html: msg
	};

	mailOptions.to = email;
	mailtransport.sendMail(mailOptions, function(err, res) {
		if (err) {
			log.err("mailing couples: " + JSON.stringify(err));
			return;
		}
	});
}

function sendEmails(msg, sub, couple) {
	if (couple) {
		getCouple(couple, function(err, cp) {
			if (err) { return; }
			mailPerson(msg, sub, cp.email);
			mailPerson(msg, sub, cp.email2);
		});
	} else {
		getCouples(function(err, couples) {
			if (err) { return; }
			var time = 100;
			couples.forEach(function(v) {
				setTimeout(function() {
					mailPerson(msg, sub, v.email);
					mailPerson(msg, sub, v.email2);
				}, time += 1000);
			});
		});
	}
}

base.listen(8010);
