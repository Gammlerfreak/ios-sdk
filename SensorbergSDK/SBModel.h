//
//  SBModel.h
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

#import "SBEnums.h"

@interface SBModel : NSObject
@end

/**
    A wrapper of the CLBeacon object to make accessing properties easier
 */
@protocol SBMBeacon @end
@interface SBMBeacon : NSObject
@property (strong, nonatomic) NSString *uuid;
@property (nonatomic) int major;
@property (nonatomic) int minor;

/**
 Initializer for SBMBeacon with a CLBeacon object

 @param beacon A CLBeacon object, provided by iOS

 @return A SBMBeacon object
 */
- (instancetype)initWithCLBeacon:(CLBeacon*)beacon;

/**
 *  Initializer for SBMBeacon with full UUID string.
 *  The length of fullUUID should be 42 (exclude hypens '-').
 *
 *  @param fullUUID hypenated or not hypenated full UUID string.
 *
 *  @return Returns SBMBeacon instance. returns nil when the length of given string is not 42.
 */
- (instancetype)initWithString:(NSString*)fullUUID;
- (NSString*)fullUUID;
- (NSUUID*)UUID;
@end

@protocol  SBMCampaignAction @end
@interface SBMCampaignAction : NSObject
@property (strong, nonatomic) NSDate        *fireDate;
@property (strong, nonatomic) NSString      *subject;
@property (strong, nonatomic) NSString      *body;
@property (strong, nonatomic) NSDictionary  *payload;
@property (strong, nonatomic) NSString      *url;
@property (strong, nonatomic) NSString      *eid;
@property (nonatomic) SBTriggerType         trigger;
@property (nonatomic) SBActionType          type;
@property (strong, nonatomic) SBMBeacon     *beacon;
@property (strong, nonatomic) NSString      *action; // unique action fire event identifier
@end
