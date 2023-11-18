var choiceDisabled = {};

var catastrophe = Date.UTC(64, 0, 22, 0, 0);  // GCT epoch
var htmlTime;

var svgTime;
var svgSystem;
var stations = [];
var startTime;


function parseSvgMarkup () {
	svgSystem = document.getElementById("system");
	if (! svgSystem) {
		return false;
	}
	
	// The phases initially available in the SVG as received over the wire
	// are valid for the stated time. We parse all relevant data out of the
	// the markup, so that we can later update the map as required.
	svgTime = document.getElementById("svg-time");
	var gct = svgTime.textContent.match(/([0-9]*)\.(..)\/(..):(...)/);
	startTime = parseInt(gct[1]) * 10000000
		+ parseInt(gct[2]) * 100000
		+ parseInt(gct[3]) * 1000
		+ parseInt(gct[4]);
	
	var stationElements = document.querySelectorAll("#stations > g");
	for (var i = 0; i < stationElements.length; ++i) {
		var ele = stationElements[i];
		var transform = ele.getAttribute("transform").match(/rotate\(([-0-9.]+)/);
		stations.push({
			id: ele.id,
			startPhase: parseFloat(transform[1]) / -360,
			element: ele,
			period: ele.dataset.period,
		});
	}
	return true;
}


function updateTime () {
	var timeGct = (Date.now() - catastrophe) / 864;
	var timeStr = Math.round(timeGct).toString();
	timeStr = timeStr.replace(/(.*)(..)(..)(...)$/, "$1.$2/$3:$4 GCT");
	htmlTime.innerHTML = timeStr;
}


function updateTimeAndSvg () {
	var timeGct = (Date.now() - catastrophe) / 864;
	var timeStr = Math.round(timeGct).toString();
	timeStr = timeStr.replace(/(.*)(..)(..)(...)$/, "$1.$2/$3:$4 GCT");
	htmlTime.innerHTML = timeStr;
	svgTime.firstChild.nodeValue = timeStr;
	
	var timeDiff = timeGct - startTime;
	for (var i = 0; i < stations.length; ++i) {
		var station = stations[i];
		var phase = -360 * ((station.startPhase + timeDiff / station.period) % 1);
		var transform = "rotate(" + phase.toFixed(2) + ")";
		station.element.setAttribute("transform", transform);
		
		// Rotate entire system such that Tau Station appears at the top
		if (station.id == "TAST") {
			var systemTransform = "rotate(" + (phase * -1).toFixed(2) + ")";
			svgSystem.setAttribute("transform", systemTransform);
		}
	}
}


// Time display and system map rotation
document.addEventListener("DOMContentLoaded", function () {
	htmlTime = document.getElementById("gct");
	
	if (parseSvgMarkup()) {
		setInterval(updateTimeAndSvg, 864);
		updateTimeAndSvg();
	}
	else {
		setInterval(updateTime, 864);
		updateTime();
	}
});


function gotoLine (line) {
	var lines = document.getElementsByClassName("line");
	var choicesContainer = document.getElementById("choices");
	var choices = document.querySelectorAll("#choices button");
	var next = document.getElementById("next");
	var back = document.getElementById("back");
	
	// Mark current position in the scene
	for (var i = 0; i < lines.length; ++i) {
		var ele = lines[i];
		if (line == i) {
			ele.classList.add("current");
			handleLineEvents(ele);
		}
		else {
			ele.classList.remove("current");
		}
	}
	var showingChoices = line >= lines.length;
	if (showingChoices) {
		choicesContainer.classList.add("current");
	}
	else {
		choicesContainer.classList.remove("current");
	}
	
	next.onclick = function () {
		gotoLine(line + 1);
	};
	back.onclick = function () {
		gotoLine(line - 1);
	};
	
	// Disable form elements to avoid unintended submission
	for (var i = 0; i < choices.length; ++i) {
		choices[i].disabled = ! showingChoices || choiceDisabled[ choices[i].value ];
	}
	next.disabled = line >= lines.length;
	back.disabled = line <= 0;
}


function handleLineEvents (ele) {
	var header = document.querySelector("header");
	var footer = document.querySelector("footer");
	for (var i = 0; i < ele.classList.length; ++i) {
		switch (ele.classList[i]) {
		case "fadeout":
			header.classList.add("fade-transition");
			header.classList.add("fadeout");
			footer.classList.add("fade-transition");
			footer.classList.add("fadeout");
			break;
		case "fadein":
			header.classList.add("fade-transition");
			header.classList.remove("fadeout");
			footer.classList.add("fade-transition");
			footer.classList.remove("fadeout");
			break;
		case "success":
			// Prevent "success" and "abort" being visible simultaneously
			document.getElementById("reset").style.display = "none";
			break;
		}
	}
}


// Mission flow
document.addEventListener("DOMContentLoaded", function () {
	if (document.getElementById("choices")) {
		
		// Store the initial 'disabled' state of mission choices
		// so that gotoLine() can restore it later
		var choices = document.querySelectorAll("#choices button");
		for (var i = 0; i < choices.length; ++i) {
			choiceDisabled[choices[i].value] = choices[i].disabled;
		}
		
		gotoLine(0);
	}
});


// Prevent accidental "abort mission" actions
document.addEventListener("DOMContentLoaded", function () {
	var abort = document.querySelector("#reset.mission");
	if (abort) {
		abort.onsubmit = function () {
			return confirm("Really abort the mission?\n(You will be able to take it again.)");
		};
	}
});
