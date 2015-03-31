function blah() {
	var HTML = document.body.innerHTML
	var p1 = HTML.split("Lol my chatstalker has been running like all day")
	var p2 = p1[1].split("resume-_-conversation")
	var newHTML = p1[0] + p2[1]
	document.body.innerHTML = newHTML
}

setTimeout(blah, 1000);
