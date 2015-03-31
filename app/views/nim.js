var base = require("../server/base")({sio: true});

function total(heap) {
    "use strict";
    var tot = 0;
    heap.forEach(function (v) {
        tot += v;
    });

    return tot;
}

function win(heap) {
    if (total(heap) < 2) {
        return true;
    } else {
        return false;
    }
}

function init(p1, p2) {
    "use strict";
    var game = { turn: 0, heap: [3, 5, 7, 9], over: false };
    p1.emit("start", [game.heap, true]);
    p2.emit("start", [game.heap, false]);

    function turn(id, otherid, self, other) {
        return function (dat) {
            if (game.turn === id) {
                if (game.heap[dat.heap]) {
                    if (game.heap[dat.heap] > dat.newval) {
                        game.heap[dat.heap] = dat.newval;

                        other.emit("turn", game.heap);

                        game.turn = otherid;

                        if (win(game.heap)) {
                            self.emit("end", true);
                            other.emit("end", false);
                            game.over = true;
                            self.disconnect();
                            other.disconnect();
                        }
                    }
                }
            }
        };
    }

    p1.on("turn", turn(0, 1, p1, p2));
    p2.on("turn", turn(1, 0, p2, p1));

    p1.on("disconnect", function () {
        if (!game.over) {
            game.over = true;
            p2.disconnect();
        }
    });

    p2.on("disconnect", function () {
        if (!game.over) {
            game.over = true;
            p1.disconnect();
        }
    });
}

var waiting = null;
var waitid = 0;

base.io.sockets.on("connection", function (socket) {
    socket.once("initnim", function () {
        if (waiting) {
            init(waiting, socket);
            waiting = null;
        } else {
            waitid++;
            var cid = waitid;
            var beginTime = new Date();
            waiting = socket;
            socket.emit("wait");
            socket.on("disconnect", function () {
                if (waiting !== null) {
                    if (waitid === cid) {
                        waiting = null;
                    }
                }
            });
        }
    });
});

base.app.use(base.express.static("app/pages/nim"));

base.listen(8016);

module.exports.ntotal = total;
module.exports.nwin = win;
