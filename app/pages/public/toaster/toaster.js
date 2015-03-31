// Copyright 2014 Sam Mauldin
// All rights reserved.
// This code is provided to you for educational viewing use only.
// You may not copy this code without express written or digital permission.

var cinit = {
	version: 3,
	toast: 0,
	tps: 0
};

var temp = {};
var data = null;

function init() {
	// Initial save data for first play
	if (!localStorage["toast"]) {
		localStorage["toast"] = JSON.stringify(cinit);
	}
	
	if (!JSON.parse(localStorage["toast"])) {
		localStorage["toast"] = JSON.stringify(cinit);
	}
}

function migrate() {
	// Migrate from old data format
	var save = JSON.parse(localStorage["toast"]);
	if (save.version == 0) {
		save.toast = 0;
		save.version = 1;
		localStorage["toast"] = JSON.stringify(save);
		return migrate();
	} else if (save.version == 1) {
		save.tps = 0;
		save.version = 2;
		localStorage["toast"] = JSON.stringify(save);
		alert("New update: You can now buy things to make toast!");
		return migrate();
	} else if (save.version == 2) {
		save.tps = 0;
		save.toast = 0;
		save.version = 3;
		localStorage["toast"] = JSON.stringify(save);
		alert("New Update: Your progress has been wiped to accommodate new game balance. Also, things are more expensive.");
		return migrate();
	} else if (save.version == 3) {
		return true;
	} else {
		if (confirm("Save corrupted, reset?")) {
			localStorage.removeItem("toast");
			init();
			alert("Save wiped");
		} else {
			alert("Well, here goes nothing. Things may blow up.");
			return false;
		}
	}
}

function load() {
	// Will not overwrite current data
	if (temp.loaded) {
		return;
	}
	init();
	migrate();
	data = JSON.parse(localStorage["toast"]);
	disp();
	scrollTo(0, 0);
	document.getElementById("version").innerHTML = data.version;
}

function save() {
	if (data) {
		localStorage["toast"] = JSON.stringify(data);
		document.getElementById("title").innerHTML = "Toaster Clicker: " + Math.round(getToast());
	}
}

// End data code

function disp() {
	document.getElementById("toastamt").innerHTML = Math.round(getToast());
	document.getElementById("toastps").innerHTML = getToastPerSecond() + "tps";
}

function getToast() {
	return data.toast;
}

function setToast(amt) {
	data.toast = amt;
	disp();
}

function getToastPerSecond() {
	return data.tps;
}

function setToastPerSecond(tps) {
	data.tps = tps;
}

function getToastPerClick() {
	return Math.max(1, getToastPerSecond() * 0.1);
}

var touch = false;

function noscroll() {
	event.preventDefault();
}

function store() {
	var modal = $.UIkit.modal("#store");
	modal.show();
}

function toast(click) {
	if (!click) {
		touch = true;
	}
	if (touch && (!click)) {
		event.preventDefault();
		setToast(getToast() + getToastPerClick());
	} else if ((!touch)) {
		setToast(getToast() + getToastPerClick());
	}
}

var obj = {
	"toaster" : [150, 0.1],
	"cat" : [1000, 1],
	"wizardcat" : [10000, 15],
	"spoon" : [20000, 50],
	"tempdial" : [15000, 100],
	"bakery" : [100000, 1000],
	"spoondragon" : [1000000, 15000],
	"catshelter" : [10000000, 20000]
};

function buy(name) {
	if (getToast() >= obj[name][0]) {
		setToast(getToast() - obj[name][0]);
		setToastPerSecond(getToastPerSecond() + obj[name][1]);
	} else {
		alert("You can't afford a " + name + ".");
	}
}

function addToast() {
	setToast(getToast() + (getToastPerSecond() / 10));
}

function resetPrompt() {
	if (confirm("Reset?")) {
		alert("Wiped!");
		localStorage.removeItem("toast");
		init();
		location.reload();
	} else {
		alert("No harm done.");
	}
}

setInterval(addToast, 100);
setInterval(save, 1000 * 5);
