//
//  SBSDKRegionsResponseObject.h
//  SensorbergSDK
//
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

#import <Availability.h>
#import <Foundation/Foundation.h>

#import "SBSDKAPIResponseObject.h"

/**
 The SBSDKRegionsResponseObject object is used to parse the REST responses of getting
 all distinct proximityUUIDs used by an app from the Sensorberg Beacon Management
 Platform into an useable object.
 */
@interface SBSDKRegionsResponseObject : SBSDKAPIResponseObject

/**
 Holds a list of regions to listen for iBeacon advertisements.

 Each regions object holds a string of the proximityUUID of a beacon id.
 */
@property (nonatomic, readonly) NSArray *regions;

@end
