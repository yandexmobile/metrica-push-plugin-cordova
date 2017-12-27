/*
 * Version for Cordova/PhoneGap
 * © 2017 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

"use strict";

var app = {
	configuration: {
        apiKey: 'Your API key here'
    },
    initialize: function() {
        document.addEventListener('deviceready', this.onDeviceReady.bind(this), false);
    },
    onDeviceReady: function() {
		window.appMetrica.activate(this.configuration);

		window.appMetricaPush.init();
		
		document.getElementById('getTokenBtn').addEventListener("click", function () {
			window.appMetricaPush.getToken(function (token) {
				document.getElementById('tokenInput').value = token;
				console.log("Token: " + token);
			});
		});
    }
};

app.initialize();
