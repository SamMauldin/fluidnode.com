var log = require("../server/log")("account-service");
var crypto = require("crypto");
var db = require("../server/db");
var nodeuuid = require("node-uuid");
var nodemailer = require("nodemailer");
var base = require("../server/base")({ sio: true });

var Account = db.models.account;

function sha512(data) {
    var shasum = crypto.createHash("sha512");
    shasum.update(data);
    return shasum.digest("hex");
}

function deviate(data, salt) {
    data += salt;
    for (i = 0; i < 500; i++) {
        data = sha512(data);
    }
    return data;
}

function genSalt() {
    return sha512(nodeuuid());
}

function signIn(username, password, cb) {
    var query = Account.findOne({ username: username });
    query.exec(function(err, acct) {
        if (err || !acct) {
            cb(JSON.stringify(err) || "Account not found");
            return;
        }
        password = deviate(password, acct.passwordsalt);
        if (password == acct.password) {
            cb(null, acct);
        } else {
            cb("Wrong password");
        }
    });
}

function signUp(username, password, email, cb) {
    var query = Account.findOne({});
    query.or([{ username: username }, { email: email }]);
    query.exec(function(err, acct) {
        if (err) {
            cb(err);
            return;
        }

        if (acct) {
            cb("Username or email already taken");
            return;
        }

        acct = new Account();

        acct.username = username;
        acct.passwordsalt = genSalt();
        acct.password = deviate(password, acct.passwordsalt);
        acct.email = email;
        acct.verificationcode = genSalt();
        acct.accountId = genSalt();
        acct.sessionId = genSalt();

        acct.save(function(err) {
            if (err) {
                cb(err);
                return;
            }
            cb(null, acct.verificationcode);
        });

    });
}

function submitVerificationCode(code, cb) {
    var query = Account.findOne({
        verificationcode: code
    });

    query.exec(function(err, acct) {
        if (err || !acct) {
            cb(err || "Nonexistant account or already verified");
        }

        acct.verificationcode = null;
        acct.verified = true;

        acct.save(function(err) {
            if (err) {
                cb(err);
                return;
            }
            cb(null, true);
        });
    });
}

function getAccountFromSession(token, cb) {
    var query = Account.findOne({
        sessionId: token
    });
    query.exec(function(err, acct) {
        if (err || !acct) {
            cb(err || "Invalid token or session reset");
            return;
        }
        cb(null, acct);
    });
}

function getAccountFromUsername(username, cb) {
    var query = Account.findOne({
        username: username
    });
    query.exec(function(err, acct) {
        if (err || !acct) {
            cb(err || "Invalid token or session reset");
            return;
        }
        cb(null, acct);
    });
}

function connectSite(acct, site, cb) {
    acct.connectedSites = acct.connectedSites || [];

    acct.connectedSites.push({
        site: site,
        key: genSalt(),
        access: {
            name: true
        }
    });

    acct.markModified("connectedSites");

    acct.save(function(err) {
        if (err) {
            cb(err);
            return;
        }
        cb(null, true);
    });
}

var mailtransport = nodemailer.createTransport({
	host: "mail.fluidnode.com",
	requireTLS: true,
	auth: {
		user: "accounts@fluidnode.com",
		pass: "6x*fjjaSKryxwqmkcwgdutupmdj.arYV"
	}
});

function sendMail(msg, sub, email) {
	var mailOptions = {
    	from: "Fluidnode Account <accounts@fluidnode.com>",
    	to: email,
    	subject: sub,
    	html: msg
	};

	mailtransport.sendMail(mailOptions, function(err, res) {
		if (err) {
			log.err("sending mail: " + JSON.stringify(err));
			return;
		}
	});

    log.log("Registering account");
}

base.app.use(base.express.static("app/pages/account"));

base.io.sockets.on("connection", function (socket) {

    socket.on("checkToken", function(data) {
        if (typeof data == "string") {
            getAccountFromSession(data, function(err, acct) {
                if (err) {
                    socket.emit("checkToken", false);
                } else {
                    socket.emit("checkToken", {
                        name: acct.username,
                        sites: acct.connectedSites
                    });
                }
            });
        } else {
            socket.emit("checkToken", false);
        }
    });

    socket.on("register", function(data) {
        if (typeof data == "object") {
            if (data.username && data.password && data.email) {
                signUp(data.username, data.password, data.email, function(err, code) {
                    if (err) {
                        socket.emit("register", false);
                        return;
                    }
                    sendMail("Hi! You've registed for a Fluidnode account. If this isn't you, please ignore this message. If it is you, please click <a href='https://account.fluidnode.com/verify?code=" + code + "'>here</a> to finish your registration.", "Fluidnode Registration", data.email);
                    socket.emit("register", true);
                });
            } else {
                socket.emit("register", false);
            }
        } else {
            socket.emit("register", false);
        }
    });

    socket.on("login", function(data) {
        if (typeof data == "object") {
            if (data.username && data.password) {
                signIn(data.username, data.password, function(err, acct) {
                    if (err) {
                        socket.emit("login", false);
                        return;
                    }
                    socket.emit("login", {
                        token: acct.sessionId,
                        name: acct.username,
                        sites: acct.connectedSites
                    });
                });
            } else {
                socket.emit("login", false);
            }
        } else {
            socket.emit("login", false);
        }
    });

    socket.on("authorizeSite", function(data) {
        if (typeof data == "object") {
            if (data.site && data.sessionId) {
                getAccountFromSession(data.sessionId, function(err, acct) {
                    if (err) {
                        socket.emit("authorizeSite", false);
                        return;
                    }
                    connectSite(acct, data.site, function(err) {
                        if (err) {
                            socket.emit("authorizeSite", false);
                            return;
                        }
                        socket.emit("authorizeSite", true);
                    });
                });
            } else {
                socket.emit("authorizeSite", false);
            }
        } else {
            socket.emit("authorizeSite", false);
        }
    });

});

base.app.all("/api/connect", function(req, res) {
    if (req.param("site") && req.param("token") && req.param("username")) {
        getAccountFromUsername(req.param("username"), function(err, acct) {
            if (err) {
                res.end("Error: Unknown user");
                return;
            }

            if (acct.connectedSites) {
                var found = false;

                acct.connectedSites.forEach(function(v) {
                    if (!found && v.site == req.param("site")) {
                        found = true;

                        if (v.key == req.param("token")) {
                            res.end("Authorized");
                        } else {
                            res.end("Error: Wrong token");
                        }

                    }
                });

                if (!found) {
                    res.end("Error: Site not authorized for this user");
                }
            } else {
                res.end("Error: Site not authorized for this user");
            }
        });
    } else {
        res.end("Error: Invalid request");
    }
});

base.app.get("/verify", function(req, res) {
    if (req.param("code")) {
        submitVerificationCode(req.param("code"), function(err) {
            if (err) {
                res.redirect("/error.html");
                return;
            }
            res.redirect("/verified.html");
        });
    } else {
        res.redirect("/error.html");
    }
});

base.listen(8022);

var base2 = require("../server/base")();

base2.app.get("/", function(req, res) {
    res.redirect("https://account.fluidnode.com");
});

base2.listen(8021);
