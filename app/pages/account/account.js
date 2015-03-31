var pages = [
    {name: "Loading", id: "#loading"},
    {name: "Register", id: "#register"},
    {name: "Registered", id: "#registered"},
    {name: "Login", id: "#login"},
    {name: "Status", id: "#status"}
];

function hidepages() {
    pages.forEach(function(v) {
        $(v.id).hide();
    });
}

function page(name) {
    hidepages();
    pages.forEach(function(v) {
        if (v.name == name) {
            $(v.id).show();
        }
    });
}

var socket = io.connect();

var connectedSites = null;

socket.on("checkToken", function(res) {
    if (res === false) {
        page("Login");
    } else if (res) {
        connectedSites = res.sites;
        $("#namespan").text(res.name);
        page("Status");
    } else {
        page("Login");
    }
});

socket.on("login", function(res) {
    if (res === false) {
        alert("Login failure");
        page("Login");
    } else if (res) {
        localStorage.accountToken = res.token;
        connectedSites = res.sites;
        $("#namespan").text(res.name);
        page("Status");
    } else {
        alert("Unknown error on the server");
        page("Login");
    }
});

socket.on("register", function(res) {
    if (res === false) {
        alert("Registration failure, try a different username or email");
        page("Register");
    } else if (res) {
        page("Registered");
    } else {
        alert("Unknown error on the server");
        page("Register");
    }
});

if (localStorage.accountToken) {
    socket.emit("checkToken", localStorage.accountToken);
    page("Loading");
} else {
    page("Login");
}

$("#viewRegister").click(function(e) {
    e.preventDefault();
    page("Register");
});

$("#viewLogin").click(function(e) {
    e.preventDefault();
    page("Login");
});

$("#submitLogin").click(function(e) {
    e.preventDefault();
    socket.emit("login", {
        username: $("#loginUsername").val(),
        password: $("#loginPassword").val()
    });
    page("Loading");
});

$("#submitRegister").click(function(e) {
    e.preventDefault();
    socket.emit("register", {
        username: $("#registerUsername").val(),
        password: $("#registerPassword").val(),
        email: $("#registerEmail").val()
    });
    page("Loading");
});

$("#logout").click(function(e) {
    e.preventDefault();
    localStorage.accountToken = null;
    page("Login");
});
