function $(id) {
	return document.getElementById(id);
}

function getHeight() {
	return window.innerHeight;
}

function checkHeight(fullScreen) {
	if (fullScreen) {
		$("content").height = getHeight();
		$("banner").height = 0;
	} else {
		$("content").height = getHeight() * 0.8;
		$("banner").height = getHeight() * 0.2;
	}
}

function setImage(id, url) {
	$(id + "span").innerHTML = '<img class="nomargin" width="auto" src="' + url + '" height="80%" id="' + id + '">';
}

function setVideo(id, url) {
	$(id + "span").innerHTML = '<video class="nomargin" width="auto" src="' + url + '" autoplay height="80%" id="' + id + '"></video>';
}

function displayClubMedia() {
	setImage("content", "test.png");
	return true;
}

function displayFSAd() {
	return false;
}

function displayBannerAd() {
	//setImage("banner", "test.png");
	return false;
}

function mainLoop() {
	if (displayFSAd()) {
		checkHeight(true);
	} else if (displayClubMedia()) {
		if (displayBannerAd()) {
			checkHeight(false);
		} else {
			checkHeight(true);
		}
	} else {
		checkHeight(true);
	}
}

setTimeout(function() {
	$("body").style.backgroundColor = "black";
	setTimeout(function() {
		setInterval(mainLoop, 1000 * 10);
		mainLoop();
	}, 1000 * 2);
}, 1000 * 10);