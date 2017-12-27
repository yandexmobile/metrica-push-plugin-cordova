/*
 * Version for Cordova/PhoneGap
 * © 2017 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

"use strict";

function appMetricaPushExec(methodName, argsArray, success) {
    var className = 'AppMetricaPush';
    cordova.exec(
        success,
        function (err) {
            console.warn('AppMetricaPush:cordova.exec(' +
                className + '.' + methodName + '): ' + err)
        },
        className,
        methodName,
        argsArray
    );
}

module.exports = {
    /**
     * Initializes AppMetrica Push SDK.
     * AppMetrica SDK should be activated before initializing of AppMetrica Push SDK.
     *
     * @see https://tech.yandex.com/appmetrica/doc/mobile-sdk-dg/concepts/push-about-docpage/
     */
	init: function () {
        appMetricaPushExec('init', [], function () {});
    },
    /**
     * Method returns current push token in function 'success'.
     * AppMetrica Push SDK should be initialized before.
     *
     * @param {function(token)} success
     */
    getToken: function (success) {
    	appMetricaPushExec('getToken', [], success);
    }
}

document.addEventListener('metricaconfigurationupdate', function (args) {
	appMetricaPushExec('saveMetricaConfig', [args.config], function () {});
}, false);