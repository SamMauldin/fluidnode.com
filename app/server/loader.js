process.env.TZ = "America/Chicago";

GLOBAL.isProduction = __dirname == "/home/ubuntu/fluidnode.com/app/server";
console.log("Running in production:" + isProduction);

if (isProduction) {
	GLOBAL.keySet = require("../../../fluidconfig/fluidnode.com/keyset").production;
} else {
	GLOBAL.keySet = require("../../../fluidconfig/fluidnode.com/keyset").development;
}

var modules = [
	"./db",
	"../views/files",
	"../views/main",
	"../views/fluid",
	"../views/nim",
	"../views/bccc",
	"../views/log",
	"../views/EnderCC",
	"../views/account"
];

modules.forEach(function(v) {
	require(v);
});
