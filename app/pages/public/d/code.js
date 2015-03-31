function status(msg) {
	$("#status").text(msg);
}

var args = window.location.search.replace("?", "").split(":");
if (args[1]) {
	Parse.initialize("2Gsw3o9TosbUR681vmEDhoiaeWHLd8bnzjvkyU3m", "BchjJ6dRQI1LYkJg9nXrd68FjnnhhpQpkHIYY5Fl");
	Parse.User.logOut();
	Parse.User.logIn(args[0], args[1], {
		success: function(user) {
			status("Ready.");
			drawTable();
		},
		error: function(user, error) {
			status("Could not login");
			alert("Login failed.");
		}
	});
} else {
	status("Could not login");
	console.log("Args not found");
	alert("Sorry");
}

var Image = Parse.Object.extend("Images");

function upload(video) {
	var fileUploadControl = $("#pictureUpload")[0];
	if (fileUploadControl.files.length > 0) {
		var filename = prompt("Name for the file?");
		console.log("Uploading file...");
		status("Uploading file...");
		var file = fileUploadControl.files[0];
		var name = "image";
		var parseFile = new Parse.File(name, file);
		parseFile.save().then(function() {
			status("Finishing up...");
			console.log("File uploaded, creating record.");
			var image = new Image();
			image.set("user", Parse.User.current());
			image.set("image", parseFile);
			image.set("video", video);
			image.set("name", filename);
			image.set("show", true);
			image.setACL(new Parse.ACL(Parse.User.current()));
			image.save({
				success: function() {
					$("#uploadcontainer").html($("#uploadcontainer").html());
					status("Ready.");
					console.log("Record created.");
					alert("File uploaded!");
					drawTable();
				},
				error: function(obj, err) {
					status("Error. Try again");
					alert("Error: " + err.message);
				}
			});
		}, function() {
			alert("Error uploading file :(");
			status("Error. Try again");
		});
	}
}

function setinterval() {
	var val = prompt("How many seconds for each image?");
	val = parseInt(val);
	if (val != NaN) {
		var user = Parse.User.current();
		user.set("seconds", val);
		user.save();
		drawTable();
	}
}

function toggle(id) {
	$("#" + id).toggleClass("red green");
	var query = new Parse.Query(Image);
	query.get(id, {
		success: function(obj) {
			obj.set("show", !obj.get("show"));
			obj.save({
				success: function() {
					drawTable();
				}
			});
		}
	});
}

function del(id) {
	if (confirm("Delete file?")) {
		var query = new Parse.Query(Image);
		query.get(id, {
			success: function(obj) {
				obj.destroy({});
				drawTable();
			}
		});
	}
}

function drawTable() {
	var query = new Parse.Query(Image);
	query.equalTo("user", Parse.User.current());
	query.find({
		success: function(results) {
			console.log("Got results");
			results.sort(function(a, b) {
				var ashow = a.attributes.show;
				var bshow = b.attributes.show;
				if (ashow == bshow) {
					var atime = a.createdAt;
					var btime = b.createdAt;
					if (atime < btime) {
						return 1;
					} else {
						return 0;
					}
				} else if (bshow === true) {
					return 1;
				} else {
					return -1;
				}
			});
			var html = "";
			results.forEach(function(v) {
				html += '<tr>';

				html += '<td>';
				if (!v.get("video")) {
					html += '<img width="100px" height="100px" src="';
					html += v.get("image").url();
					html += '">';
				} else {
					html += 'Video<br/>No preview available';
				}
				html += '</td>';

				html += '<td>';

				html += '<button id="' + v.id + '" class="circle ';
				if (v.get("show")) {
					html += "green";
				} else {
					html += "red";
				}
				html += '" onclick="toggle(\'';
				html += v.id;
				html += '\')"> </button><br/><br/>';

				html += v.get("name");

				html += '</td>';

				html += '<td>';

				html += '<button class="uk-button uk-button-mini uk-button-danger" onclick="del(\'' + v.id + '\')">Delete</button>';

				html += '</td>';

				html += '</tr>';
			});
			$("#imagetable").html(html);
		}
	});
	$("#interval").text(Parse.User.current().get("seconds"));
}

setInterval(drawTable, 1000 * 15);
