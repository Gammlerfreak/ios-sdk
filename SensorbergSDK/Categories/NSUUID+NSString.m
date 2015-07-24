//
//  NSUUID+NSString.m
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

#import "NSUUID+NSString.h"

@implementation NSUUID (NSString)

+ (BOOL)isValidUUIDString:(NSString *)UUIDString {
    return (BOOL)[[NSUUID alloc] initWithUUIDString:UUIDString];
}

+ (NSString *)stripHyphensFromUUIDString:(NSString *)UUIDString {
    if (UUIDString.length != 36) {
        return nil;
    }

    return [UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

+ (NSString *)hyphenateUUIDString:(NSString *)UUIDString {
    if (UUIDString.length != 32) {
        return nil;
    }

    NSMutableString *resultString = [NSMutableString stringWithString:UUIDString];

    [resultString insertString:@"-" atIndex:8];
    [resultString insertString:@"-" atIndex:13];
    [resultString insertString:@"-" atIndex:18];
    [resultString insertString:@"-" atIndex:23];

    return [resultString copy];
}

@end
