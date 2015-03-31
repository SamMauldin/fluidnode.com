var base = require("../server/base")();

base.app.all("*", function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    next();
});

base.app.use(base.express.static("app/pages/public"));

base.app.get("/ping", function(req, res) {
    res.send("pong");
});

base.app.get("/version", function(req, res) {
	res.send(process.version);
});

base.app.get("/time", function(req, res) {
	res.send((""+(new Date()).getTime()));
});

base.listen(8015);
