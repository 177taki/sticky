'use strict'

var CryptoJS = require('crypto-js');

const MILIEUAPI = __MILIEU_API__;
const HOST = __HOST__;

var config = {
	apiKey: __FIREBASE_APIKEY__,
	authDomain: __FIREBASE_AUTHDOMAIN__,
	databaseURL: __FIREBASE_DATABASEURL__,
	storageBucket: __FIREBASE_STORAGEBUCKET__
};
firebase.initializeApp(config);

chrome.runtime.onMessage.addListener(function(request, sender) {
	if ( !(sender.tab.highlighted && request.msg == "feedFound") )
		return;

	firebase.auth().currentUser.getToken(true).then(function(token) {
		//todo: need to use token to be verified by the backend server
		var sensor = firebase.auth().currentUser.uid;
		var input = [];
		for (var i = 0; i < request.feeds.length; ++i) {
			var a = document.createElement('a');
			a.href = request.feeds[i].href;
			if (a.protocol == "http:" || a.protocol == "https:") {
				input.push(request.feeds[i]);
			} else {
				console.log('Warning: feed source rejected (wrong protocol): ' +
					request.feeds[i].href);
			}
		}

		if (input.length == 0)
			return;

		var encoder = createEncoder();

		Promise.all(input.map(function(item) {
			return findFeeds(item.href);
		})).then(function (input) {

			var xhr = new XMLHttpRequest()
			xhr.responseType = "json";
			xhr.addEventListener("loadend", function() {
				if (xhr.status === 200) {
					var json = {};
					json.sensor = sensor
					encoder.set(xhr.response.title, xhr.response.url, xhr.response.image)
					json.data = input.map(function(item) {
						return encoder.encode(item);
					});
					var xhr2 = new XMLHttpRequest();
					xhr2.addEventListener("loadend", function() {
						if (xhr2.status === 200) {
						} else {
							console.error(xhr2.status+' '+xhr2.statusText);
						}
					});
					xhr2.open('POST', HOST+MILIEUAPI, true);
					xhr2.setRequestHeader( 'Content-Type', 'application/json; charset=utf-8' );
					xhr2.send(JSON.stringify(json));
				} else {
					console.error(xhr.status+' '+xhr.statusText);
				}
			});
			xhr.open('POST', "http://api.hitonobetsu.com/ogp/analysis?url="+sender.tab.url, true);
			xhr.send();
		});
	}).catch(function(error) {
		//todo: handle error
	});
});

function createEncoder() {
	var hour, ampm, unixtime, currentUrl, currentTitle, imageUrl;
	return {
		set: function(title, url, image) {
			var time = new Date();
			hour = time.getHours() > 12 ? (time.getHours() - 12).toString() : time.getHours().toString();
			ampm =  time.getHours() > 12 ? 'PM' : 'AM';
			unixtime = Math.round( time.getTime() / 1000 );
			currentUrl = url;
			currentTitle = title;
			imageUrl = image;
			return;
		},
		encode: function(feed) {
			var series = {};
			var indexOfUri = 5
			series.id = CryptoJS.SHA256(feed.id.slice(indexOfUri)).toString(CryptoJS.enc.Hex).toUpperCase();
			series.attributes = {}
			series.attributes.version = "0.1"
			series.attributes.title = feed.title;
			series.attributes.uri = feed.id.slice(indexOfUri);
			series.attributes.mainpage = feed.website;
			series.attributes.icon = feed.iconUrl;
			series.attributes.image = feed.visualUrl ? feed.visualUrl : imageUrl;
			series.attributes.depiction = feed.description;
			if (feed.topics) {
				series.attributes.subject = feed.topics[0];
			}
			var context = {}
			context.moment = hour+" "+ampm;
			context.address = currentTitle;
			context.website = currentUrl;
			context.situation = "www";
			context.look = imageUrl;
			context.timestamp = unixtime;
			var data = {}
			data.context = context
			data.series = series
			return data;
		}
	}
}

function findFeeds(URL) {
	return new Promise(function(resolve, reject) {
		var req = new XMLHttpRequest();
		req.open('GET', "http://cloud.feedly.com/v3/feeds/"+ encodeURIComponent("feed/"+URL), true);
		req.responseType = "json";
		req.onload = function() {
			if (req.status === 200) {
				resolve(req.response);
			}
			else {
				reject(new Error(req.statusText));
			}
		};
		req.onerror = function() {
			reject(new Error(req.statusText));
		};
		req.send();
	});
}

