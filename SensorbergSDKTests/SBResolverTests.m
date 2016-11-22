//
//  SBResolverTests.m
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

#import "SBTestCase.h"
#import "SBResolver.h"
#import "SBInternalEvents.h"
#import <tolo/Tolo.h>

FOUNDATION_EXPORT NSString *const kSBIdentifier;

@interface SBResolver ()
- (void)publishSBEventGetLayoutWithBeacon:(SBMBeacon*)beacon trigger:(SBTriggerType)trigger error:(NSError *)error;
- (NSString *)currentTargetAttributeString;
@end

@interface SBResolverTests : SBTestCase
@property (nonatomic, strong) SBResolver *sut;
@property (nonatomic, strong) SBEvent *event;
@property (nonatomic, strong) XCTestExpectation *postLayoutExpectation;
@end

@implementation SBResolverTests

- (void)setUp {
    [super setUp];
    self.sut = [[SBResolver alloc] initWithApiKey:@"TestAPIKey"];
    [[Tolo sharedInstance] subscribe:self.sut];
}

- (void)tearDown {
    
    [[Tolo sharedInstance] unsubscribe:self.sut];
    self.sut = nil;
    self.postLayoutExpectation = nil;
    self.event = nil;
    [super tearDown];
}

- (void)test000Initialization {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSBIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:kSBIdentifier];
    XCTAssert(value);
}

- (void)test001TargetAttributes {
    SBEventUpdateTargetAttributes *event = [SBEventUpdateTargetAttributes new];
    event.targetAttributes = @{@"b" : @"100", @"a" : @(0), @"z" : @[@"array", @"value"]};
    PUBLISH(event);
    
    NSString *tartgetAttributesString = [self.sut currentTargetAttributeString];
    // check also sort order : alpabetical acending 
    XCTAssertEqualObjects(tartgetAttributesString, @"a=0&b=100&z=array,value");
}

- (void)test002ClearTargetAttributes {
    SBEventUpdateTargetAttributes *event = [SBEventUpdateTargetAttributes new];
    PUBLISH(event);
    
    NSString *tartgetAttributesString = [self.sut currentTargetAttributeString];
    XCTAssertNil(tartgetAttributesString);
}

- (void)test003EmptyTargetAttributes {
    SBEventUpdateTargetAttributes *event = [SBEventUpdateTargetAttributes new];
    event.targetAttributes = @{};
    PUBLISH(event);
    
    NSString *tartgetAttributesString = [self.sut currentTargetAttributeString];
    XCTAssertTrue(!tartgetAttributesString.length);
}

SUBSCRIBE(SBEventGetLayout)
{
    self.event = event;
}

- (void)test000PublishSBEventGetLayoutWithBeaconTriggerError
{
    REGISTER();
    self.sut = [[SBResolver alloc] initWithApiKey:@"TestAPIKey"];
    SBMBeacon *defaultBeacon = [[SBMBeacon alloc] initWithString:@"7367672374000000ffff0000ffff00030000200747"];
    [self.sut publishSBEventGetLayoutWithBeacon:defaultBeacon trigger:1 error:nil];
    SBEventGetLayout *event = (SBEventGetLayout *)self.event;
    XCTAssert([event.beacon isEqual:defaultBeacon]);
    XCTAssert(event.trigger == 1);
    XCTAssertNil(event.error);
    UNREGISTER();
}

SUBSCRIBE(SBEventPostLayout)
{
    self.event = event;
    [self.postLayoutExpectation fulfill];
}

@end
