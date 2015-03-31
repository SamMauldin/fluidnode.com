// Note to future self
// Example domain formats
// https://account.fluidnode.com (No port if default port, includes plain http)
// http://cat.fluidnode.com:8020

var socket = io.connect();

var warned = false;
var otherWindow = null;
var otherWindowOrigin = null;
var connectedSites = null;
var username = null;
var loggedIn = false;
var loggingIn = false;
var allowed = null;
var alreadyAdded = null;
var siteToken = null;

if (localStorage.accountToken) {
    socket.emit("checkToken", localStorage.accountToken);
    loggingIn = true;
}

socket.on("authorizeSite", function(res) {
    if (res) {
        alert("Logged in with Fluidnode Account!");
    } else {
        alert("Logging in with Fluidnode Account failed!");
    }
});

socket.on("checkToken", function(res) {
    if (res === false) {
        // Auth failure
    } else if (res) {
        loggedIn = true;
        connectedSites = res.sites;
        username = res.name;
        if (otherWindow) {
            otherWindow.postMessage({
                req: "loggedIn",
                res: [username, otherWindowOrigin]
            }, otherWindowOrigin);
            connectedSites.forEach(function(v) {
                if (v.site == otherWindowOrigin) {
                    siteToken = v.key;
                    allowed = true;
                    alreadyAdded = true;
                }
            });
            allowed = allowed || confirm("Authenticate " + otherWindowOrigin + " with Fluidnode Account?");
            if (allowed && !alreadyAdded) {
                socket.emit("authorizeSite", {
                    sessionId: localStorage.accountToken,
                    site: otherWindowOrigin
                });
            }
        }
    } else {
        // Something weird
    }
    loggingIn = false;
});

var authorizedSites = {
    "https://bccc.fluidnode.com": true,
    "https://account.fluidnode.com": true
};

window.addEventListener("message", function(event) {

    var site = event.origin;
    var data = event.data;
    var reply = function(data) {
        event.source.postMessage(data, event.origin);
    };

    if (authorizedSites[event.origin]) {
        otherWindow = otherWindow || event.source;
        otherWindowOrigin = otherWindowOrigin || event.origin;
        if (data && data.req) {
            if (data.req == "authorize") {
                reply({
                    req: "authorized",
                    res: (loggedIn ? true : (loggingIn ? "Not logged in yet" : "Not logged in"))
                });
            } else if (data.req == "getToken") {

                if (siteToken) {
                    event.source.postMessage({
                        req: "getToken",
                        res: [true, siteToken]
                    }, event.origin);
                } else if (loggedIn && (allowed || allowed === null)) {
                    event.source.postMessage({
                        req: "getToken",
                        res: [false, "wait"]
                    }, event.origin);
                } else if (loggedIn && !allowed) {
                    event.source.postMessage({
                        req: "getToken",
                        res: [false, false]
                    }, event.origin);
                } else if (loggingIn) {
                    event.source.postMessage({
                        req: "getToken",
                        res: [false, "wait"]
                    }, event.origin);
                } else {
                    event.source.postMessage({
                        req: "getToken",
                        res: [false, false, true]
                    }, event.origin);
                }

            } else {
                console.log("Unknown request");
            }
        } else {
            console.log("Unknown request");
        }
    } else {
        if (!warned) {
            warned = true;
            alert("This site isn't authorized to use Fluidnode Account. If you're developing a site, email accounts@fluidnode.com");
        }
        console.log("Unauthorized site: " + event.origin);
        reply({
            error: "Unauthorized site",
            site: event.origin
        });
    }

}, false);
