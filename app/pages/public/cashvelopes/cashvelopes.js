function size() {
    var width = window.innerWidth;
    if (width < 500) {
        document.getElementById("content1").style["background-image"] = 'url("http://placekitten.com/g/200/500")';
    } else if (width < 700) {
        document.getElementById("content1").style["background-image"] = 'url("http://placekitten.com/g/500/500")';
    } else {
        document.getElementById("content1").style["background-image"] = 'url("http://placekitten.com/g/700/500")';
    }
}

window.onresize = size;

window.onready = size;
