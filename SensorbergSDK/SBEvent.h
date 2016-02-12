//
//  SBEvent.h
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

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "SBModel.h"

#pragma mark - Application life-cycle events

/**
 *  @brief          The root class for all Sensorberg SDK events.
 *
 *  @param error    By subclassing SBEvent, all published events contain an `error` property of NSError type
 *
 *  @since          2.0
 */
@interface SBEvent : NSObject
@property (strong, nonatomic) NSError *error;
@end

/**
 *  @brief          Event fired when a beacon is resolved to a campaign that should fire.
 *
 *  @param error    campaign A SBCampaignAction object
 *
 *  @since          2.0
 */
@interface SBEventPerformAction : SBEvent
@property (strong, nonatomic) SBMCampaignAction *campaign;
@end

@interface SBEventResetManager : SBEvent
@end

@interface SBEventReportHistory : SBEvent
@end

#pragma mark - Location events

@interface SBEventRangedBeacon : SBEvent
@property (strong, nonatomic) SBMBeacon *beacon;
@property (nonatomic) int rssi;
@property (nonatomic) CLProximity proximity;
@property (nonatomic) CLLocationAccuracy accuracy;
@end

@interface SBEventDeterminedState : SBEvent
@property (strong, nonatomic) NSString *uuid;
@property (nonatomic) int state;
@end

@interface SBEventRegionEnter : SBEventRangedBeacon
@property (strong, nonatomic) CLLocation *location;
@end

@interface SBEventRegionExit : SBEvent
@property (strong, nonatomic) SBMBeacon *beacon;
@property (strong, nonatomic) CLLocation *location;
@end

#pragma mark - Authorization events

@interface SBEventLocationAuthorization : SBEvent
@property (nonatomic) SBLocationAuthorizationStatus locationAuthorization;
@end

@interface SBEventBluetoothAuthorization : SBEvent
@property (nonatomic) SBBluetoothStatus bluetoothAuthorization;
@end

@interface SBEventNotificationsAuthorization : SBEvent
@property (nonatomic) BOOL notificationsAuthorization;
@end

#pragma mark - CoreBluetooth events

@interface SBEventBluetoothEmulation : SBEvent
@end