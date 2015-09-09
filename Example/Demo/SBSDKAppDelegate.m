//
//  SBSDKAppDelegate.m
//  SensorbergSDK
//
//  Created by Max Horvath on 09/09/2014.
//  Copyright (c) 2014 Sensorberg GmbH. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "SBSDKAppDelegate.h"
#import <SensorbergSDK/SBSDKBeaconAction.h>

#import <objc/runtime.h> // Required for proper UIAlertView handling

static void *const SBSDKAppDelegateInAppMessageUrlKey    = (void *)&SBSDKAppDelegateInAppMessageUrlKey;
static void *const SBSDKAppDelegateInAppPayloadKey       = (void *)&SBSDKAppDelegateInAppPayloadKey;


static NSString *const SBSDKAppDelegateLocalNotificationActionIdKey = @"SBSDKAppDelegateLocalNotificationActionIdKey";
static NSString *const SBSDKAppDelegateLocalNotificationUrlKey      = @"SBSDKAppDelegateLocalNotificationUrlKey";
static NSString *const SBSDKAppDelegateLocalNotificationPayloadKey  = @"SBSDKAppDelegateLocalNotificationPayloadKey";

NSString *const SBSDKAppDelegateDetectedBeaconsUpdated = @"SBSDKAppDelegateDetectedBeaconsUpdated";
NSString *const SBSDKAppDelegateAvailabilityStatusChanged = @"SBSDKAppDelegateAvailabilityStatusChanged";

@implementation SBSDKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSError *connectionError;

    #ifdef __IPHONE_8_0
        // Request permission to display notifications on iOS 8
        if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings
                                                                settingsForTypes:UIUserNotificationTypeSound | UIUserNotificationTypeAlert
                                                                categories:nil];

            [application registerUserNotificationSettings:notificationSettings];
        }
    #endif
        
    // Bootstrap Sensorberg SDK
    self.beaconManager = [[SBSDKManager alloc] initWithDelegate:self];

    [self.beaconManager requestAuthorization];

    [self.beaconManager connectToBeaconManagementPlatformUsingApiKey:@"a64a5a229b488c85a65b500c5b8cf1da88bdc191713e4194cb56c8c6a6f7fc59"
                                                               error:&connectionError];

    if (!connectionError) {
        [self.beaconManager requestAuthorization];
        [self.beaconManager startMonitoringBeacons];

    } else {
        NSLog(@"there was an connection error: %@", connectionError.localizedDescription);
    }

    return YES;
}

#pragma mark - Local Notifications

- (void)displayLocalNotificationWithTitle:(NSString *)title message:(NSString *)message url:(NSURL *)url actionId:(NSString *)actionId delayInSeconds:(NSNumber *)seconds {
    // Check if we should invalidate older versions of the local notification.
    UILocalNotification *localNotification = self.localNotifications[actionId];

    if (localNotification != nil) {
        [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
    }

    // Construct local notification.
    localNotification = [[UILocalNotification alloc] init];

    localNotification.alertBody = [NSString stringWithFormat:@"%@\n%@", title, message];
    localNotification.alertAction = @"Open";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    if (seconds.integerValue > 0) {
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:seconds.doubleValue];
    }

    if (url == nil) {
        localNotification.userInfo = @{ SBSDKAppDelegateLocalNotificationActionIdKey : actionId };
    } else {
        localNotification.userInfo = @{ SBSDKAppDelegateLocalNotificationActionIdKey : actionId,
                                        SBSDKAppDelegateLocalNotificationUrlKey : [NSKeyedArchiver archivedDataWithRootObject:url] };
    }

    self.localNotifications[actionId] = localNotification;

    if (seconds.integerValue > 0) {
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    } else {
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, notification.alertBody);

    NSString *actionId = notification.userInfo[SBSDKAppDelegateLocalNotificationActionIdKey];

    if (actionId != nil) {
        [self.localNotifications removeObjectForKey:actionId];
        [[UIApplication sharedApplication] cancelLocalNotification:notification];
    }

    NSDictionary * payload = notification.userInfo[SBSDKAppDelegateLocalNotificationPayloadKey];
    //do something awesome with the payload!!!

    
    

    if (notification.userInfo[SBSDKAppDelegateLocalNotificationUrlKey]) {
        NSURL *url = [NSKeyedUnarchiver unarchiveObjectWithData:notification.userInfo[SBSDKAppDelegateLocalNotificationUrlKey]];

        if (url != nil) {
            // To open the URL immediately, we put it in a GCD dispatcher
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:url];
            });
        }
    }
}

#ifdef __IPHONE_8_0
    - (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
        NSLog(@"%s local notification %@", __PRETTY_FUNCTION__, notificationSettings.types & UIUserNotificationTypeNone ? @"denied" : @"allowed");
    }
#endif

#pragma mark - Optional beacon manager delegate methods

- (void)beaconManager:(SBSDKManager *)manager didChangeAvailabilityStatus:(SBSDKManagerAvailabilityStatus)availabilityStatus {
    NSLog(@"%s iBeacon readiness: %@", __PRETTY_FUNCTION__, availabilityStatus == SBSDKManagerAvailabilityStatusFullyFunctional ? @"fully functional" : @"restricted");
}

- (void)beaconManager:(SBSDKManager *)manager didChangeBluetoothStatus:(SBSDKManagerBluetoothStatus)bluetoothStatus {
    NSLog(@"%s bluetooth powered %@", __PRETTY_FUNCTION__, bluetoothStatus == SBSDKManagerBluetoothStatusPoweredOn ? @"on" : @"off");

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateAvailabilityStatusChanged object:self];
}

- (void)beaconManager:(SBSDKManager *)manager bluetoothDidFailWithBluetoothStatus:(SBSDKManagerBluetoothStatus)bluetoothStatus {
    NSLog(@"%s bluetooth failed, powered %@", __PRETTY_FUNCTION__, bluetoothStatus == SBSDKManagerBluetoothStatusPoweredOn ? @"on" : @"off");
}

- (void)beaconManager:(SBSDKManager *)manager didChangeBackgroundAppRefreshStatus:(SBSDKManagerBackgroundAppRefreshStatus)backgroundAppRefreshStatus {
    NSLog(@"%s background app refresh %@", __PRETTY_FUNCTION__, backgroundAppRefreshStatus == SBSDKManagerBackgroundAppRefreshStatusAvailable ? @"enabled" : @"disabled");

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateAvailabilityStatusChanged object:self];
}

- (void)beaconManager:(SBSDKManager *)manager backgroundAppRefreshDidFailWithBackgroundAppRefreshStatus:(SBSDKManagerBackgroundAppRefreshStatus)backgroundAppRefreshStatus {
    NSLog(@"%s background app refresh failed, it is %@", __PRETTY_FUNCTION__, backgroundAppRefreshStatus == SBSDKManagerBackgroundAppRefreshStatusAvailable ? @"enabled" : @"disabled");
}

- (void)beaconManager:(SBSDKManager *)manager didChangeAuthorizationStatus:(SBSDKManagerAuthorizationStatus)authorizationStatus {
    NSLog(@"%s app is %@", __PRETTY_FUNCTION__, authorizationStatus == SBSDKManagerAuthorizationStatusAuthorized ? @"authorized" : @"not authorized");

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateAvailabilityStatusChanged object:self];
}

- (void)beaconManager:(SBSDKManager *)manager authorizationDidFailWithAuthorizationStatus:(SBSDKManagerAuthorizationStatus)authorizationStatus {
    NSLog(@"%s authorization failed, app is %@", __PRETTY_FUNCTION__, authorizationStatus == SBSDKManagerAuthorizationStatusAuthorized ? @"authorized" : @"not authorized");
}

- (void)beaconManager:(SBSDKManager *)manager didChangeSensorbergPlatformConnectionState:(SBSDKManagerConnectionState)connectionState {
    NSLog(@"%s %@ to Sensorberg Platform", __PRETTY_FUNCTION__, connectionState == SBSDKManagerConnectionStateConnected ? @"connected" : @"not connected");

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateAvailabilityStatusChanged object:self];
}

- (void)beaconManager:(SBSDKManager *)manager didChangeSensorbergPlatformReachabilityState:(SBSDKManagerReachabilityState)reachabilityState {
    NSLog(@"%s Sensorberg Platform is %@", __PRETTY_FUNCTION__, reachabilityState == SBSDKManagerReachabilityStateReachable ? @"reachable" : @"not reachable");

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateAvailabilityStatusChanged object:self];
}

- (void)beaconManager:(SBSDKManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, [(CLBeaconRegion *) region proximityUUID].UUIDString);
}

- (void)beaconManager:(SBSDKManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"%s %@: %@", __PRETTY_FUNCTION__, region, [error localizedDescription]);
}

- (void)beaconManager:(SBSDKManager *)manager didStartRangingForRegion:(CLRegion *)region {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, [(CLBeaconRegion *) region proximityUUID].UUIDString);
}

- (void)beaconManager:(SBSDKManager *)manager didStopRangingForRegion:(CLRegion *)region {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, [(CLBeaconRegion *) region proximityUUID].UUIDString);
}

- (void)beaconManager:(SBSDKManager *)manager rangingDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"%s %@: %@", __PRETTY_FUNCTION__, region, [error localizedDescription]);
}

- (void)beaconManager:(SBSDKManager *)manager didDetectBeaconEnterEventForBeacon:(CLBeacon *)beacon {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, beacon.proximityUUID.UUIDString);
}

- (void)beaconManager:(SBSDKManager *)manager didDetectBeaconExitEventForBeacon:(CLBeacon *)beacon {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, beacon.proximityUUID.UUIDString);
}

- (void)beaconManager:(SBSDKManager *)manager didUpdateDetectedBeacons:(NSArray *)detectedBeacons {
    // This will constantly output beacon detections.
    // NSLog(@"%s %@", __PRETTY_FUNCTION__, [detectedBeacons description]);

    [[NSNotificationCenter defaultCenter] postNotificationName:SBSDKAppDelegateDetectedBeaconsUpdated object:self];
}

#pragma mark - Beacon action delegate method

- (void)beaconManager:(SBSDKManager *)manager didResolveAction:(SBSDKBeaconAction *)action {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive || action.delaySeconds.integerValue > 0){
        [self displayLocalNotificationWithTitle:action.subject message:action.body url:action.url actionId:action.actionId delayInSeconds:action.delaySeconds];
    } else {
        NSDictionary * payload = action.payload;
        //do something usefull with the payload, we´e boring and will just show an UIAlertView

        NSString * body;
        if (payload){
            body = [NSString stringWithFormat:@"%@\nPayload:\n%@", action.body, [action.payload description]];
        } else {
            body = action.body;
        }

        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:action.subject
                                                             message:body
                                                            delegate:self
                                                   cancelButtonTitle:@"Ignore"
                                                   otherButtonTitles:@"Open URL", nil];
        objc_setAssociatedObject(alertView, SBSDKAppDelegateInAppMessageUrlKey, action.url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(alertView, SBSDKAppDelegateInAppPayloadKey, payload, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [alertView show];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Check for associated URL to be presented to the user.
    NSURL *url = objc_getAssociatedObject(alertView, SBSDKAppDelegateInAppMessageUrlKey);
    NSDictionary * payload = objc_getAssociatedObject(alertView, SBSDKAppDelegateInAppPayloadKey);
    //do something usfull with the payload. We´e boring and we´l just open the URL

    if ((alertView.firstOtherButtonIndex == buttonIndex) && (url != nil)) {
        [[UIApplication sharedApplication] openURL:url];
    }
}



@end
