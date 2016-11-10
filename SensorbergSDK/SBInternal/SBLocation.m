//
//  SBLocation.m
//  SensorbergSDK
//
//  Copyright (c) 2014-2016 Sensorberg GmbH. All rights reserved.
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

#import "SBLocation.h"

#import "NSString+SBUUID.h"

#import "SBUtility.h"

#import <tolo/Tolo.h>

#import <UIKit/UIApplication.h>

#import "SensorbergSDK.h"

#import "SBInternalEvents.h"

#import "SBEvent.h"

#import "SBInternalModels.h"

#import "SBSettings.h"

#import <objc_geohash/GeoHash.h>

@interface SBLocation() {
    CLLocationManager *locationManager;
    //
    NSArray *monitoredRegions;
    //
    NSMutableDictionary *sessions;
    //
    NSDate *appActiveDate;
}

@end

@implementation SBLocation

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        //
        sessions = [NSMutableDictionary new];
        //
    }
    return self;
}

#pragma mark - External methods

- (void)requestAuthorization:(BOOL)always {
    if (![CLLocationManager locationServicesEnabled]) {
        PUBLISH(({
            SBEventLocationAuthorization *event = [SBEventLocationAuthorization new];
            event.locationAuthorization = SBLocationAuthorizationStatusUnavailable;
            event;
        }));
        return;
    }
    //
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] && ![CLLocationManager isMonitoringAvailableForClass:[CLRegion class]]) {
        PUBLISH(({
            SBEventLocationAuthorization *event = [SBEventLocationAuthorization new];
            event.locationAuthorization = SBLocationAuthorizationStatusUnavailable;
            event;
        }));
        return;
    }
    //
    if (always) {
        [locationManager requestAlwaysAuthorization];
    } else {
        [locationManager requestWhenInUseAuthorization];
    }
    //
    if ([self authorizationStatus] == SBLocationAuthorizationStatusUnimplemented) {
        PUBLISH(({
            SBEventLocationAuthorization *event = [SBEventLocationAuthorization new];
            event.locationAuthorization = SBLocationAuthorizationStatusUnimplemented;
            event;
        }));
        //
        SBLog(@"Please set \"NSLocationAlwaysUsageDescription\" or \"NSLocationWhenInUseUsageDescription\" in info.plist of your Application!!");
    }
}

- (SBLocationAuthorizationStatus)authorizationStatus {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    SBLocationAuthorizationStatus authStatus;
    
    if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] &&
        ![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]){
        authStatus = SBLocationAuthorizationStatusUnimplemented;
        return authStatus;
    }
    //
    switch (status) {
        case kCLAuthorizationStatusRestricted:
        {
            authStatus = SBLocationAuthorizationStatusRestricted;
            break;
        }
        case kCLAuthorizationStatusDenied:
        {
            authStatus = SBLocationAuthorizationStatusDenied;
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            authStatus = SBLocationAuthorizationStatusAuthorized;
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            authStatus = SBLocationAuthorizationStatusAuthorized;
            break;
        }
        case kCLAuthorizationStatusNotDetermined:
        {
            authStatus = SBLocationAuthorizationStatusNotDetermined;
            break;
        }
    }
    //
    return authStatus;
}

- (void)startMonitoring:(NSArray *)regions {
    if (self.isMonitoring) {
        [self stopMonitoring];
    }
    //
    _isMonitoring = YES;
    monitoredRegions = [NSArray arrayWithArray:regions];
    
    for (NSString *region in monitoredRegions) {
        if ([GeoHash verifyHash:region] && region.length<12) {
            [self startMonitoringForGeoRegion:region];
        } else {
            [self startMonitoringForBeaconRegion:region];
        }
    }
}

- (void)startBackgroundMonitoring {
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        SBLog(@"Started significant location changes monitoring");
        [locationManager stopMonitoringSignificantLocationChanges];
        [locationManager startMonitoringSignificantLocationChanges];
    } else {
        SBLog(@"X Background monitoring not available");
    }
}

- (void)stopBackgroundMonitoring {
    SBLog(@"Stopped significant location changes monitoring");
    [locationManager stopMonitoringSignificantLocationChanges];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    PUBLISH(({
        SBEventLocationAuthorization *event = [SBEventLocationAuthorization new];
        event.locationAuthorization = [self authorizationStatus];
        event;
    }));
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self checkExitForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    switch (state) {
        case CLRegionStateInside: {
            if ([region isKindOfClass:[CLBeaconRegion class]]) {
                [locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
            }
            break;
        }
        case CLRegionStateOutside: {
            [self checkExitForRegion:region];
            break;
        }
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    if (beacons.count == 0) {
        return;
    }
    //
    [self updateSessionsWithBeacons:beacons];
    //
    [self checkExitForRegion:region];
    //
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    [self handleLocationError:error];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    [self handleLocationError:error];
    // do we need to do something with the region?
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    _gps = locations.lastObject;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self handleLocationError:error];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    [self handleLocationError:error];
}

#pragma mark - Internal methods

- (void)updateSessionsWithBeacons:(NSArray *)beacons {
    if (!sessions) {
        sessions = [NSMutableDictionary new];
    }
    
    for (CLBeacon *beacon in beacons) {
        SBMBeacon *sbBeacon = [[SBMBeacon alloc] initWithCLBeacon:beacon];
        
        SBMSession *session = [sessions objectForKey:sbBeacon.fullUUID];
        if (!session) {
            session = [[SBMSession alloc] initWithUUID:sbBeacon.fullUUID];
            // Because we don't have a session with this beacon, let's fire an SBEventRegionEnter event
            PUBLISH(({
                SBEventRegionEnter *enter = [SBEventRegionEnter new];
                enter.beacon = sbBeacon;
                enter.rssi = [NSNumber numberWithInteger:beacon.rssi].intValue;
                enter.proximity = beacon.proximity;
                enter.accuracy = beacon.accuracy;
                enter.location = _gps;
                enter;
            }));
        }
        session.lastSeen = [[NSDate date] timeIntervalSince1970];
        if (session.exit) {
            session.exit = 0;
        }
        //
        [sessions setObject:session forKey:sbBeacon.fullUUID];
        //
        if (beacon.proximity!=CLProximityUnknown) {
            PUBLISH(({
                SBEventRangedBeacon *event = [SBEventRangedBeacon new];
                event.beacon = sbBeacon;
                event.rssi = [NSNumber numberWithInteger:beacon.rssi].intValue;
                event.proximity = beacon.proximity;
                event.accuracy = beacon.accuracy;
                event;
            }));
        }
    }
}

- (void)checkExitForRegion:(CLRegion *)region {
    //
    NSTimeInterval monitoringDelay = [SBSettings sharedManager].settings.monitoringDelay;
    NSTimeInterval rangingDelay = [SBSettings sharedManager].settings.rangingSuppression;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    for (SBMSession *session in sessions.allValues) {
        if (session.lastSeen + monitoringDelay <= now ) {
            if (session.exit<=0) {
                SBLog(@"Setting exit for %@", session.pid);
                session.exit = now;
            } else if ( session.exit + rangingDelay <= now ) {
                PUBLISH(({
                    SBEventRegionExit *exit = [SBEventRegionExit new];
                    exit.beacon = [[SBMBeacon alloc] initWithString:session.pid];
                    exit.location = _gps;
                    exit;
                }));
            }
        }
    }
}

- (void)startMonitoringForBeaconRegion:(NSString *)region {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[NSString hyphenateUUIDString:region]];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[kSBIdentifier stringByAppendingPathExtension:region]];
    [locationManager startMonitoringForRegion:beaconRegion];
    SBLog(@"Started monitoring for %@",beaconRegion.identifier);
}

- (void)stopMonitoring {
    for (CLRegion *region in locationManager.monitoredRegions.allObjects) {
        if ([region.identifier rangeOfString:kSBIdentifier].location!=NSNotFound) {
            [locationManager stopMonitoringForRegion:region];
            SBLog(@"Stopped monitoring for %@",region.identifier);
        }
    }
}

- (void)handleLocationError:(NSError *)error {
    if (isNull(error)) {
        return;
    }
    SBLog(@"Location error: %@", error);
    switch (error.code) {
        case kCLErrorDenied: {
            // user denied!
            break;
        }
        case kCLErrorRangingUnavailable: {
            // airplane mode, location or bluetooth unavailable!
            break;
        }
        case kCLErrorRegionMonitoringDenied: {
            // user denied access to region monitoring!
            break;
        }
        case kCLErrorRegionMonitoringSetupDelayed: {
            // region monitoring was delayed
            break;
        }
        case kCLErrorRegionMonitoringFailure: {
            // failed to start monitoring for a region (too many monitored regions or radius of geofence is too high
            break;
        }
        case kCLErrorRangingFailure: {
            // general ranging error
            break;
        }
        case kCLErrorRegionMonitoringResponseDelayed: {
            SBLog(@"Alternate region: %@",kCLErrorUserInfoAlternateRegionKey);
            break;
        }
        default:
            break;
    }
}

- (void)startMonitoringForGeoRegion:(NSString *)region {
    // TODO
}

#pragma mark - Events
#pragma mark SBEventApplicationWillEnterForeground
SUBSCRIBE(SBEventApplicationWillEnterForeground) {
    appActiveDate = [NSDate date];
}

#pragma mark SBEventApplicationDidEnterBackground
SUBSCRIBE(SBEventApplicationDidEnterBackground) {
    
}

SUBSCRIBE(SBEventRegionExit) {
    [sessions removeObjectForKey:event.beacon.fullUUID];
    SBLog(@"Session closed for %@", event.beacon.fullUUID);
}

#pragma mark - For Unit Tests

- (NSDictionary *)currentSessions {
    return [sessions copy];
}

@end
