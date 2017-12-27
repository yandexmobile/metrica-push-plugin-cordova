/*
 * Version for Cordova/PhoneGap
 * © 2017 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

#import <Cordova/CDVPlugin.h>

@interface AppMetricaPush : CDVPlugin <UIApplicationDelegate>

- (void)init:(CDVInvokedUrlCommand *)command;
- (void)getToken:(CDVInvokedUrlCommand *)command;

@end

