//
//  SensorbergSDK.h
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

#import <CoreBluetooth/CoreBluetooth.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

//! Project version number for SensorbergSDK.
FOUNDATION_EXPORT double SensorbergSDKVersionNumber;

//! Project version string for SensorbergSDK.
FOUNDATION_EXPORT const unsigned char SensorbergSDKVersionString[];

#import "SBManager.h"

#import "SBEvent.h"
#import "SBModel.h"
#import "SBEnums.h"

#import "SBBluetooth.h"

#ifdef __cplusplus
extern "C" {
#endif
    void sbLogFuncC_impl(const char * f, int l, const char * fmt, ...) __attribute__ ((format (__printf__, 3, 4)));
#define sbLogFunc sbLogFuncC_impl
    
#ifdef __OBJC__
    
    void sbLogFuncObjC_impl(const char * f, int l, NSString * fmt, ...) NS_FORMAT_FUNCTION(3,4);
#undef sbLogFunc
#define sbLogFunc sbLogFuncObjC_impl
    
#endif
    
#ifdef __cplusplus
}
#endif

#define SB_NO_LOGGING

#ifdef SB_NO_LOGGING
#define SBLog(s...) do {} while(0)
#else
#define SBLog(s...) sbLogFunc(__FILE__, __LINE__, s)
#endif

#define emptyImplementation(className)      @implementation className @end

#define kSBCacheFolder      [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]

#define now                 [NSDate date]

extern NSString *const kSBDefaultResolver;

extern NSString *const kSBDefaultAPIKey;

extern NSString             *kPostLayout;

extern NSString             *kSBAppActive;

extern float                kPostSuppression;

// general SensorbergSDK domain
extern NSString *const                      kSBIdentifier;
// ```Resolver``` date format
extern NSString *const                      APIDateFormat;

//

@interface SensorbergSDK : NSObject

+ (NSString *)applicationIdentifier;

// default beacon regions with keys as proximity uuid's and the common name as the value
+ (NSDictionary *)defaultBeaconRegions;

// don't use this :)
+ (BOOL)debugging;

@end
