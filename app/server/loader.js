process.env.TZ = "America/Chicago";

GLOBAL.isProduction = __dirname == "/home/ubuntu/fluidnode.com/app/server";
console.log("Running in production:" + isProduction);

if (isProduction) {
	GLOBAL.keySet = require("./keys").production;
} else {
	GLOBAL.keySet = require("./keys").development;
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
