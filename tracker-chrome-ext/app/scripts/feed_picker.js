'use strict'

pickFeedLinks();


function pickFeedLinks() {
  var rsses = document.evaluate(
      '//*[local-name()="link"][contains(@rel, "alternate")] ' +
      '[contains(@type, "rss")]', document, null, 0, null);
  var atoms = document.evaluate(
      '//*[local-name()="link"][contains(@rel, "alternate")] ' +
      '[contains(@type, "atom")]', document, null, 0, null);

  var feeds = [];
  var item;
  var count = 0;
  while (item = rsses.iterateNext()) {
    feeds.push({"href": item.href, "title": item.title});
    ++count;
  }

	if (count <= 0) {
		while (item = atoms.iterateNext()) {
			feeds.push({"href": item.href, "title": item.title});
			++count;
		}
	}
	console.table(feeds);

	if (count <= 0) {
		return;
	}

	chrome.runtime.sendMessage({msg: "feedFound", feeds: feeds});
}

