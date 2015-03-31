var mongoose = require("mongoose");
var Schema = mongoose.Schema;

mongoose.connect(keySet.mongodb);
var db = mongoose.connection;

module.exports.models = {};

var coupleSchema = new Schema({
    coupleId: String,
    agent: String,
    comments: String,
    done: Boolean,
    eating: Boolean,
    email: String,
    email2: String,
    name: String,
    playing: Boolean,
    windowsxp: Boolean,
    step: Number,
    substitute: String
});

module.exports.models.couple = mongoose.model("Couple", coupleSchema);

var tournamentSchema = new Schema({
    only: Boolean,
    stage: Number,
    arrive: String,
    day: String,
    details: String,
    format: String,
    menu: String,
    time: String
});

module.exports.models.tournament = mongoose.model("Tournament", tournamentSchema);

var weatherSchema = new Schema({
    humidity: Number,
    pressure: Number,
    rain: Number,
    temp: Number,
    windDirection: String,
    windSpeed: Number,
    rainStorm: Number,
    rainToday: Number,
    windAngle: Number,
    time: Number,
    forecast: String
});

module.exports.models.weather = mongoose.model("Weather", weatherSchema);

var accountSchema = new Schema({
    username: String,
    password: String,
    passwordsalt: String,
    email: String,
    accountId: String,
    sessionId: String,
    verified: Boolean,
    verificationcode: String,
    connectedSites: [{
        site: String,
        key: String,
        access: {
            name: Boolean
        }
    }]
});

module.exports.models.account = mongoose.model("Account", accountSchema);

var endernetSessionSchema = new Schema({
    sessionID: String,
    publicID: String,
    channelID: String,
    lastChecked: Number,
    messages: [{
        fromID: String,
        message: String
    }]
});

module.exports.models.endernetSession = mongoose.model("EndernetSession", endernetSessionSchema);

module.exports.db = db;
module.exports.mongoose = mongoose;
