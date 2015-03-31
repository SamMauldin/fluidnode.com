/*jslint node: true */

var base = require("../server/base")();

base.app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    next();
});

base.app.use("/", base.express.static("app/pages/files"));

var serveIndex = require("serve-index");
base.app.use("/", serveIndex("app/pages/files", {
    filter: function (name) {
        return name !== "hidden";
    }
}));

base.listen(8012);
