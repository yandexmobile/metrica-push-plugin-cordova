/*
 * Version for Cordova/PhoneGap
 * © 2017 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

package com.yandex.metrica.push.plugin.cordova;

import android.content.Context;
import android.support.annotation.NonNull;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.yandex.metrica.YandexMetricaConfig;
import com.yandex.metrica.plugin.cordova.AppMetricaPlugin;
import com.yandex.metrica.push.YandexMetricaPush;
import com.yandex.metrica.push.plugin.MetricaConfigStorage;

public class AppMetricaPush extends CordovaPlugin {

    @Override
    public boolean execute(@NonNull final String action, @NonNull final JSONArray args,
						   @NonNull final CallbackContext callbackContext) throws JSONException {
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run() {
				if ("init".equals(action)) {
					init();
				} else if ("getToken".equals(action)) {
					getToken(callbackContext);
				} else if ("saveMetricaConfig".equals(action)) {
					saveMetricaConfig(args, callbackContext);
				} else {
					callbackContext.error("Unknown action: " + action);
				}
			}
		});
        return true;
    }
    
    private void init() {
    	final Context context = cordova.getActivity().getApplicationContext();
    	YandexMetricaPush.init(context);
    }
    
    private void getToken(@NonNull final CallbackContext callbackContext) {
    	final String token = YandexMetricaPush.getToken();
    	callbackContext.success(token);
    }
    
    private void saveMetricaConfig(@NonNull final JSONArray args,
								   @NonNull final CallbackContext callbackContext) {
    	try {
	    	final JSONObject configObj = args.getJSONObject(0);
    	    final YandexMetricaConfig config = AppMetricaPlugin.toConfig(configObj);
    	    final Context context = cordova.getActivity().getApplicationContext();

	    	final MetricaConfigStorage metricaConfigStorage = new MetricaConfigStorage(context);
    		metricaConfigStorage.saveConfig(config);
    	} catch (JSONException ex) {
    		callbackContext.error(ex.getMessage());
    	}
    }
}
