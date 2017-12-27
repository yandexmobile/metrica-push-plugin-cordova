/*
 * Version for Cordova/PhoneGap
 * © 2017 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

#import <Cordova/CDVAppDelegate.h>
#import <YandexMobileMetricaPush/YandexMobileMetricaPush.h>
#import <YandexMobileMetrica/YandexMobileMetrica.h>
#import <objc/runtime.h>

#import "AppMetricaPush.h"
#import "YMMAppMetricaPlugin.h"

static NSString *const kYMPUserDefaultsConfigurationKey = @"com.yandex.mobile.metrica.push.sdk.Configuration";

static BOOL gYMPIsTokenSent = YES;
static NSData *gYMPToken = nil;

void ymp_saveActivationConfigurationJSON(NSDictionary *config);
static bool ymp_ensureAppMetricaActivated();

@implementation AppMetricaPush

- (void)init:(CDVInvokedUrlCommand *)command
{
}

- (void)getToken:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:gYMPToken.description];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)saveMetricaConfig:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        NSDictionary *configurationDictionary = [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];
        ymp_saveActivationConfigurationJSON(configurationDictionary);
        if (gYMPIsTokenSent == NO && ymp_ensureAppMetricaActivated()) {
            [YMPYandexMetricaPush setDeviceTokenFromData:gYMPToken];
            gYMPIsTokenSent = YES;
        }
    }];
}

@end

@implementation CDVAppDelegate(AppMetricaPush)

#define RECURSION_CHECK(CMD) if ([NSStringFromSelector(_cmd) rangeOfString:@"ymp_"].location == 0) { CMD; }

- (BOOL)ymp_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    RECURSION_CHECK(return YES);
    
    [self registerForPushNotificationsWithApplication:application];
    
    // Call the original method
    BOOL result = [self ymp_application:application didFinishLaunchingWithOptions:launchOptions];
    
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] != nil) {
        // We should activate AppMetrica first to handle push notification
        ymp_ensureAppMetricaActivated();
    }
    
    // Enable in-app push notifications handling in iOS 10
    if ([UNUserNotificationCenter class] != nil) {
        id<YMPUserNotificationCenterDelegate> delegate = [YMPYandexMetricaPush userNotificationCenterDelegate];
        delegate.nextDelegate = [UNUserNotificationCenter currentNotificationCenter].delegate;
        [UNUserNotificationCenter currentNotificationCenter].delegate = delegate;
    }
    
    [YMPYandexMetricaPush handleApplicationDidFinishLaunchingWithOptions:launchOptions];
    
    return result;
}

- (void)ymp_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    RECURSION_CHECK(return);
    
    gYMPToken = deviceToken;
    if (ymp_ensureAppMetricaActivated()) {
        // We have to ensure that AppMetrica activated here
        [YMPYandexMetricaPush setDeviceTokenFromData:deviceToken];
        gYMPIsTokenSent = YES;
    }
    else {
        gYMPIsTokenSent = NO;
    }
    
    // Call the original method
    return [self ymp_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)ymp_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    RECURSION_CHECK(return);
    
    [self ymp_handleRemoteNotification:userInfo];
    
    // Call the original method
    return [self ymp_application:application didReceiveRemoteNotification:userInfo];
}

- (void)ymp_application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
 fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    RECURSION_CHECK(return);
    
    [self ymp_handleRemoteNotification:userInfo];
    
    // Call the original method
    [self ymp_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (void)ymp_handleRemoteNotification:(NSDictionary *)userInfo
{
    // We should activate AppMetrica first to handle push notification
    ymp_ensureAppMetricaActivated();
    [YMPYandexMetricaPush handleRemoteNotification:userInfo];
}

- (void)registerForPushNotificationsWithApplication:(UIApplication *)application
{
    // Register for push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes =
            UIUserNotificationTypeAlert |
            UIUserNotificationTypeBadge |
            UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    else {
        UIRemoteNotificationType notificationTypes =
            UIRemoteNotificationTypeBadge |
            UIRemoteNotificationTypeSound |
            UIRemoteNotificationTypeAlert;
        [application registerForRemoteNotificationTypes:notificationTypes];
    }
}

#undef RECURSION_CHECK

@end

void ymp_saveActivationConfigurationJSON(NSDictionary *config)
{
    if (config == nil) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:config forKey:kYMPUserDefaultsConfigurationKey];
}

bool ymp_ensureAppMetricaActivated()
{
    if ([YMMAppMetricaPlugin isAppMetricaActivated]) {
        // AppMetrica is already activated
        return true;
    }
    
    bool result = false;
    NSDictionary *configurationDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kYMPUserDefaultsConfigurationKey];
    if (configurationDictionary != nil) {
        // Activating AppMetrica with some cached configuration
        [YMMAppMetricaPlugin activateWithConfigurationDictionary:configurationDictionary];
        result = [YMMAppMetricaPlugin isAppMetricaActivated];
    }
    return result;
}

static void ymp_appdelegateMethodsSwap(SEL origSel, SEL ympSel)
{
    Class cls = [CDVAppDelegate class];
    Method origMethod = class_getInstanceMethod(cls, origSel);
    Method ympMethod = class_getInstanceMethod(cls, ympSel);
    
    if (origMethod != NULL) {
        method_exchangeImplementations(origMethod, ympMethod);
    }
    else {
        const char *types = method_getTypeEncoding(ympMethod);
        IMP ympImp = method_getImplementation(ympMethod);
        if (ympImp != NULL) {
            class_addMethod(cls, origSel, ympImp, types);
        }
    }
}

static void ymp_swizleApplicationDelegate()
{
#pragma clang diagnostic push
#pragma clang diagnostic error "-Wundeclared-selector"
    
#define SWAP_APPDELEGATE_METHODS(SEL) ymp_appdelegateMethodsSwap(@selector(SEL), @selector(ymp_ ## SEL))
    
    SWAP_APPDELEGATE_METHODS(application:didFinishLaunchingWithOptions:);
    SWAP_APPDELEGATE_METHODS(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    SWAP_APPDELEGATE_METHODS(application:didReceiveRemoteNotification:);
    SWAP_APPDELEGATE_METHODS(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    
#undef SWAP_APPDELEGATE_METHODS
#pragma clang diagnostic pop
}

__attribute__((constructor))
static void ymp_initializeAppMetricaPushPlugin()
{
    ymp_swizleApplicationDelegate();
}


