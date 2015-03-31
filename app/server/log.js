module.exports = function(name) {
    return {
        log: function(msg) {
            console.log((new Date().toString()) + ": fluidnode-" + name + ": info: " + msg);
        },

        err: function(msg) {
            console.log((new Date().toString()) + ": fluidnode-" + name + ": err: " + msg);
        }
    };
};
