var db = require("../server/db");
var log = require("../server/log")("weather-server");
var Weather = db.models.weather;
var base = require("../server/base")();

var weathercache;

base.app.get("/forecast", function (req, res) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    res.send(JSON.stringify(weathercache));
});

function updatecache() {
    var query = Weather.findOne({});
    query.sort("-time");
    query.exec(function(err, weather) {
        if (err) {
            log.err(err);
            return;
        }
        weathercache = weather;
        weathercache.forecast = weathercache.forecast;
    });
}

updatecache();
setInterval(updatecache, 1000 * 90);

base.app.use(base.express.static("app/pages/fluid"));

base.listen(8013);
