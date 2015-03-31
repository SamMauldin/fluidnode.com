var target = "https://account.fluidnode.com";

window.onload = function() {
    var iframe = document.createElement("iframe");

    iframe.onload = fluidnodeAccountReady;
    iframe.id = "fluidnodeaccountiframe";
    iframe.src = "https://account.fluidnode.com/siteapi";
    iframe.style = "display: none";

    document.body.appendChild(iframe);
};

var siteToken = null;
var username = null;
var thisSiteOrigin;
var tokenCallback = null;

fluidnodeAccount = {};

fluidnodeAccount.onSiteToken = function(cb) {
    if (siteToken) {
        setTimeout(function() {
            cb(false, siteToken);
        }, 0);
    } else {
        fluidnodeAccount.authorize();
        tokenCallback = cb;
        var contentWindow = document.getElementById("fluidnodeaccountiframe").contentWindow;
        contentWindow.postMessage({
            req: "getToken"
        }, target);
    }
};

fluidnodeAccount.authorize = function() {
    var contentWindow = document.getElementById("fluidnodeaccountiframe").contentWindow;
    contentWindow.postMessage({
        req: "authorize"
    }, target);
};

fluidnodeAccount.getContentWindow = function() {
    return document.getElementById("fluidnodeaccountiframe").contentWindow;
};

window.addEventListener("message", function(data) {
    if ((data.origin == target || target == "*") && !siteToken) {
        var theData = data.data;
        if (theData.req == "getToken") {
            if (theData.res[0] === true) {
                siteToken = theData.res[1];
                if (tokenCallback) {
                    tokenCallback(null, siteToken, username, thisSiteOrigin);
                }
            } else if (theData.res[1] === false) {
                if (tokenCallback) {
                    tokenCallback("Not authorized");
                }
            } else if (theData.res[1] == "wait") {
                setTimeout(function() {
                    fluidnodeAccount.getContentWindow().postMessage({
                        req: "getToken"
                    }, target);
                }, 1000);
            } else if (theData.res[2] === true) {
                if (tokenCallback) {
                    tokenCallback("Not logged in");
                }
            }
        } else if (theData.req == "loggedIn") {
            username = theData.res[0];
            thisSiteOrigin = theData.res[1];
            setTimeout(function() {
                fluidnodeAccount.getContentWindow().postMessage({
                    req: "getToken"
                }, target);
            }, 1000);
        }
    }
}, false);
