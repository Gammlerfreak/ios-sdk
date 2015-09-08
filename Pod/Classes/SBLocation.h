//
//  SBLocation.h
//  SensorbergSDK
//
//  Copyright (c) 2014-2015 Sensorberg GmbH. All rights reserved.
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

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#pragma mark - Enums

/**
 SBManagerAuthorizationStatus
 
 Represents the app’s authorization status for using location services.
 
 @since 0.7.0
 */

typedef NS_ENUM(NSInteger, SBLocationAuthorizationStatus) {
    /**
     User has not yet made a choice with regards to this application
     */
    SBLocationAuthorizationStatusNotDetermined,
    
    /**
     Authorization procedure has not been fully implemeneted in app.
     NSLocationAlwaysUsageDescription is missing from Info.plist.
     */
    SBLocationAuthorizationStatusUnimplemented,
    
    /**
     This application is not authorized to use location services. Due
     to active restrictions on location services, the user cannot change
     this status, and may not have personally denied authorization.
     
     Do not warn the user if the value of this property is set to
     SBManagerAuthorizationStatusRestricted; a restricted user does not have
     the ability to enable multitasking for the app.
     */
    SBLocationAuthorizationStatusRestricted,
    
    /**
     User has explicitly denied authorization for this application, or
     location services are disabled in Settings.
     */
    SBLocationAuthorizationStatusDenied,
    
    /**
     User has granted authorization to use their location at any time,
     including monitoring for regions, visits, or significant location changes.
     */
    SBLocationAuthorizationStatusAuthorized,
    
    /**
     This application runs on a device that does not support iBeacon.
     */
    SBLocationAuthorizationStatusUnavailable
};


@interface SBLocation : NSObject <CLLocationManagerDelegate> {
    
    //
}

- (void)requestAuthorization;

@property (nonatomic, readonly) BOOL iBeaconsAvailable;

- (SBLocationAuthorizationStatus)authorizationStatus;

- (void)startMonitoring:(NSArray*)regions;

- (void)startBackgroundMonitoring;

@end
