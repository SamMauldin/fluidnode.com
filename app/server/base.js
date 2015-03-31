module.exports = function(opt) {
    opt = opt || {};

    var base = {};
    base.app = require("express")();
    base.express = require("express");
    var compression = require("compression");
    base.app.use(compression());
    base.server = require("http").createServer(base.app);

    if (opt.sio) {
        base.io = require("socket.io")(base.server);
    }

    base.listen = function(port) {
        base.server.listen(port, "0.0.0.0");
    };
    
    base.oneHour = 3600;
    return base;
};
