'use strict'

var config = {
	apiKey: __FIREBASE_APIKEY__,
	authDomain: __FIREBASE_AUTHDOMAIN__,
	databaseURL: __FIREBASE_DATABASEURL__,
	storageBucket: __FIREBASE_STORAGEBUCKET__
};
firebase.initializeApp(config);

function initExt() {
	firebase.auth().onAuthStateChanged(function(user) {
		if (user) {
			document.getElementById('signout').disabled = false;
			document.getElementById('status').textContent = 'Signed in: '+ user.displayName;
		}
		else {
			//startAuth(false);
			document.getElementById('signout').disabled = true;
			document.getElementById('signin-button').disabled = false;
			document.getElementById('status').textContent = 'Signed out';
		}
	});
	document.getElementById('signin-button').addEventListener('click', startSignIn, false);
	document.getElementById('signout').addEventListener('click', signOut, false);
}

function startAuth(interactive) {
	chrome.identity.getAuthToken({ interactive: !!interactive }, function(token) {
		if (chrome.runtime.lastError && !interactive) {
			console.log('It was not possible to get a token programmatically.');
			document.getElementById('signin-button').disabled = false;
		} else if (chrome.runtime.lastError) {
			console.error(chrome.runtime.lastError);
		} else if (token) {
			var credential = firebase.auth.GoogleAuthProvider.credential(null, token);
			firebase.auth().signInWithCredential(credential).catch(function(error) {
				if (error.code === 'auth/invalid-credential') {
					chrome.identity.removeCachedAuthToken({ token: token }, function() {
						startAuth(interactive);
					});
				}
			});
		} else {
			console.error('The OAuth token was null');
		}
	});
}

function startSignIn() {
	document.getElementById('signin-button').disabled = true;
	startAuth(true);
}

function signOut() {
	firebase.auth().signOut();
}

window.onload = function () { initExt(); };
