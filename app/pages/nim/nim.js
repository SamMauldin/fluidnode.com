/*jslint bitwise: true, devel: true, browser: true */
/*global analytics*/
/*exported nim, NimCtrl, restart*/

// Nim AI
function nim(heaps, misere) {
    "use strict";

    var X = 0,
        max = 0,
        sums = [],
        chosen_heap = null,
        to_remove = null,
        twomore = 0,
        heaps_one = 0;


    heaps.forEach(function (v) {
        max = Math.max(v, max);
        X = X ^ v;
    });

    if (X === 0) {

        heaps.forEach(function (v, k) {
            if (v > 0) {
                chosen_heap = k;
                to_remove = v;
            }
        });

    } else {
        heaps.forEach(function (v, k) {
            sums[k] = (v ^ X) < v;
            if (sums[k]) {
                chosen_heap = k;
                to_remove = heaps[chosen_heap] - (heaps[chosen_heap] ^ X);
            }
        });

        heaps.forEach(function (v, k) {
            var n = chosen_heap === k ? v - to_remove : v;
            if (n > 1) {
                twomore += 1;
            }
        });

        if (twomore === 0) {
            heaps.forEach(function (v, k) {
                if (v === max) {
                    chosen_heap = k;
                }
                if (v === 1) {
                    heaps_one += 1;
                }
            });

            if (heaps_one % 2 == (misere ? 0 : 1)) {
            	to_remove = heaps[chosen_heap] - 1;
            } else {
            	to_remove = heaps[chosen_heap];
            }
        }
    }

    return [chosen_heap, to_remove];
}

// Nim Controller
function NimCtrl($scope) {
    "use strict";
    var io = window.io || {}, //JSLint hack
        socket = io.connect({ reconnect: false });

    $scope.game = [0, 0, 0, 0];
    $scope.textdat = "Connecting to server";
    $scope.cturn = false;
    $scope.sel = null;

    $scope.show = function (id) {
        if ($scope.cturn) {
            if (id === "end") {
                return $scope.sel === null;
            } else {
                if ($scope.game[id] === 0) {
                    return true;
                }
                if ($scope.sel === null) {
                    return false;
                } else {
                    return $scope.sel !== id;
                }
            }
        } else {
            return true;
        }
    };

    $scope.take = function (id) {
        $scope.sel = id;
        if ($scope.game[id] > 0) {
            $scope.game[id] -= 1;
        }
    };

    $scope.endturn = function () {
        socket.emit("turn", { heap: $scope.sel, newval: $scope.game[$scope.sel] });
        $scope.cturn = false;
        $scope.sel = null;
        $scope.textdat = "Opponents turn";
    };

    socket.on("connect", function () {
        $scope.textdat = "Connection established...";
        $scope.$apply();
        socket.emit("initnim");
    });

    socket.on("wait", function () {
        $scope.textdat = "Searching for opponent... Send this to your friends?";
        $scope.$apply();
    });

    socket.on("start", function (dat) {
        if (dat[1]) {
            $scope.textdat = "Your turn";
            $scope.cturn = true;
        } else {
            $scope.textdat = "Opponents turn";
        }

        $scope.game = dat[0];

        $scope.$apply();
    });

    socket.on("turn", function (dat) {
        $scope.game = dat;
        $scope.cturn = true;
        $scope.textdat = "Your turn";
        $scope.$apply();
    });

    socket.on("end", function (win) {
        analytics.track("Nim game played", {
            won: win
        });
        $scope.ended = true;
        $scope.textdat = (win ? "You win!" : "You lose!");
        $scope.cturn = false;
        $scope.$apply();
    });

    socket.on("disconnect", function () {
        if (!$scope.ended) {
            $scope.cturn = false;
            $scope.textdat = "Lost connection to server";
            $scope.$apply();
        }
    });
}

function restart() {
    "use strict";

    if (confirm("Restart?")) {
        location.reload();
    }
}
