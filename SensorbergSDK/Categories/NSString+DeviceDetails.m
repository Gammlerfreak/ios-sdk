//
//  NSString+DeviceDetails.m
//  SensorbergSDK
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

#import "NSString+DeviceDetails.h"

@implementation NSString (DeviceDetails)

+ (NSString *)deviceFamilyString {
    NSString *deviceType = NSLocalizedString(@"iOS device", @"'iOS device' used in DeviceDetails category of NSString.");

    GBDeviceDetails *deviceDetails = [GBDeviceInfo deviceDetails];

    switch (deviceDetails.family) {
        case GBDeviceFamilyiPhone:
            deviceType = NSLocalizedString(@"iPhone", @"'iPhone' used in DeviceDetails category of NSString.");
            break;

        case GBDeviceFamilyiPad:
            deviceType = NSLocalizedString(@"iPad", @"'iPad' used in DeviceDetails category of NSString.");
            break;

        case GBDeviceFamilyiPod:
            deviceType = NSLocalizedString(@"iPod", @"'iPod' used in DeviceDetails category of NSString.");
            break;

        case GBDeviceFamilySimulator:
            deviceType = NSLocalizedString(@"iOS Simulator", @"'iOS Simulator' used in DeviceDetails category of NSString.");
            break;

        default:
            break;
    }

    return deviceType;
}

@end
