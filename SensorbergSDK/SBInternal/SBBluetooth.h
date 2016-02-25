//
//  SBBluetooth.h
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

#import <CoreBluetooth/CoreBluetooth.h>

#import "SBEnums.h"
#import "SBModel.h"

@interface SBBluetooth : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>

/**
 *  Singleton instance of the SBBluetooth, CoreBluetooth wrapper
 *
 *  @return SBBluetooth instance (singleton)
 */
+ (instancetype)sharedManager;

/**
 *  @brief Call this method before using any Bluetooth functionality
 *
 *  @since 2.0
 */
- (void)requestAuthorization;


/**
 *  @brief Returns a @SBBluetoothStatus value
 *
 *  @return One of SBBluetoothUnknown, SBBluetoothOff, SBBluetoothOn
 *
 *  @since 2.0
 */
- (SBBluetoothStatus)authorizationStatus;

/**
 *  @brief Advertise a software emulated beacon
 *
 *  @param proximityUUID The proximity UUID of the emulated beacon
 *  @param major         Value for the major identifier
 *  @param minor         Value for the minor identifier
 *  @param name          Name for the emulated beacon
 *
 *  @since 2.0
 */
- (void)startAdvertising:(NSString *)proximityUUID major:(int)major minor:(int)minor name:(NSString*)name;


/**
 *  @brief Stops advertising the emulated iBeacon
 *
 *  @since 2.0
 */
- (void)stopAdvertising;

@end
