//
//  SBAnalyticsTests.m
//  SensorbergSDK
//
//  Created by Sanggeon Park on 23/05/16.
//  Copyright © 2016 Sensorberg GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBEvent.h"
#import "SBAnalytics.h"
#import "SBInternalEvents.h"
#import <tolo/Tolo.h>

@interface SBMGetLayout (XCTests)
- (SBMCampaignAction *)campainActionWithAction:(SBMAction *)action beacon:(SBMBeacon *)beacon trigger:(SBTriggerType)trigger;
@end

@interface SBAnalyticsTests : XCTestCase
@property (nonatomic, strong) SBAnalytics *sut;
@property (nonatomic, strong) SBMBeacon *sbBeacon;
@end

@implementation SBAnalyticsTests

- (void)setUp {
    [super setUp];
    self.sut = [SBAnalytics new];
    self.sbBeacon = [[SBMBeacon alloc] initWithString:@"7367672374000000ffff0000ffff00030000200747"];
    [[Tolo sharedInstance] subscribe:self.sut];
}

- (void)tearDown {
    [[Tolo sharedInstance] unsubscribe:self.sut];
    self.sbBeacon = nil;
    [super tearDown];
}

- (void)testSBEventRegionEnterEvent {
    SBEventRegionEnter *event = [SBEventRegionEnter new];
    event.beacon = self.sbBeacon;
    event.location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    PUBLISH(event);
    
    NSArray <SBMMonitorEvent> *events = [self.sut events];
    BOOL hasEnteredBeacon = NO;
    
    for (SBMMonitorEvent *monitorEvent in events)
    {
        if ([monitorEvent.pid isEqualToString:self.sbBeacon.fullUUID] && monitorEvent.trigger == kSBTriggerEnter)
        {
            hasEnteredBeacon = YES;
            break;
        }
    }
    
    XCTAssert(hasEnteredBeacon);
}

- (void)testSBEventRegionExitEvent {
    SBEventRegionExit *event = [SBEventRegionExit new];
    event.beacon = self.sbBeacon;
    event.location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    PUBLISH(event);
    
    NSArray <SBMMonitorEvent> *events = [self.sut events];
    BOOL hasEnteredBeacon = NO;
    
    for (SBMMonitorEvent *monitorEvent in events)
    {
        if ([monitorEvent.pid isEqualToString:self.sbBeacon.fullUUID] && monitorEvent.trigger == kSBTriggerExit)
        {
            hasEnteredBeacon = YES;
            break;
        }
    }
    
    XCTAssert(hasEnteredBeacon);
}

- (void)testSBEventPerformAction
{
    NSDictionary *layoutDict = [@{
                                @"accountProximityUUIDs" : [@[@"7367672374000000ffff0000ffff0003"] mutableCopy],
                                @"actions" : [@[
                                                [@{
                                                   @"eid": @"367348a0dfa84492a0078ead26cf9385",
                                                   @"trigger": @(kSBTriggerEnter),
                                                   @"beacons": @[
                                                           @"7367672374000000ffff0000ffff00030000200747"
                                                           ],
                                                   @"suppressionTime": @(-1),
                                                   @"content": @{
                                                           @"subject": @"SBGetLayoutTests",
                                                           @"body": @"testCheckCampaignsForBeaconAndTriggerShouldFire",
                                                           @"payload": [NSNull null],
                                                           @"url": @"http://www.sensorberg.com"
                                                           },
                                                   @"type": @(1),
                                                   @"timeframes": [@[
                                                                     [@{
                                                                        @"start": @"2016-05-01T10:00:00.000+0000",
                                                                        @"end": @"2100-05-31T23:00:00.000+0000"
                                                                        } mutableCopy]
                                                                     ] mutableCopy],
                                                   @"sendOnlyOnce": @(NO),
                                                   @"typeString": @"notification"
                                                   } mutableCopy]
                                                ] mutableCopy],
                                @"currentVersion": @(NO)
                                } mutableCopy];
    
    SBMGetLayout *newLayout = [[SBMGetLayout alloc] initWithDictionary:layoutDict error:nil];
    SBEventPerformAction *event = [SBEventPerformAction new];
    event.campaign = [newLayout campainActionWithAction:newLayout.actions[0] beacon:self.sbBeacon trigger:kSBTriggerEnter];
    PUBLISH(event);
    
    NSArray <SBMReportAction> *actions = [self.sut actions];
    BOOL hasReportAction = NO;
    
    for (SBMReportAction *reportAction in actions)
    {
        if ([reportAction.pid isEqualToString:self.sbBeacon.fullUUID] &&
            reportAction.trigger == kSBTriggerEnter &&
            [reportAction.eid isEqualToString:event.campaign.eid])
        {
            hasReportAction = YES;
            break;
        }
    }
    
    XCTAssert(hasReportAction);
}

- (void)testSBEventReportConversion
{
    NSString *eid = @"This Is the Test eid.";
    SBEventReportConversion *event = [SBEventReportConversion new];
    event.eid = eid;
    event.conversionType = kSBConversionSuccessful;
    
    PUBLISH(event);
    
    NSArray <SBMReportConversion> *conversions = [self.sut conversions];
    BOOL hasReportConversion = NO;
    
    for (SBMReportConversion *reportConversion in conversions)
    {
        if ([reportConversion.eid isEqualToString:eid] &&
            reportConversion.type == kSBConversionSuccessful)
        {
            hasReportConversion = YES;
            break;
        }
    }
    
    XCTAssert(hasReportConversion);
}


- (void)testSBEventReportConversionWithIgnoredConversionType
{
    NSString *eid = @"This Is the Test eid.";
    SBEventReportConversion *event = [SBEventReportConversion new];
    event.eid = eid;
    event.conversionType = kSBConversionIgnored;
    
    PUBLISH(event);
    
    NSArray <SBMReportConversion> *conversions = [self.sut conversions];
    BOOL hasReportConversion = NO;
    
    for (SBMReportConversion *reportConversion in conversions)
    {
        if ([reportConversion.eid isEqualToString:eid] &&
            reportConversion.type == kSBConversionIgnored)
        {
            hasReportConversion = YES;
            break;
        }
    }
    
    XCTAssert(hasReportConversion);
}

- (void)testSBPostLayoutEvent
{
    PUBLISH(((( {SBEventPostLayout *event = [SBEventPostLayout new]; event;}))));
    NSArray <SBMReportAction> *actionsAfterEvent = [self.sut actions];
    NSArray <SBMReportConversion> *conversionsAfterEvent = [self.sut conversions];
    NSArray <SBMMonitorEvent> *eventsAfterEvent = [self.sut events];
    
    XCTAssertFalse(actionsAfterEvent.count);
    XCTAssertFalse(conversionsAfterEvent.count);
    XCTAssertFalse(eventsAfterEvent.count);
}

- (void)testSBEventReportConversionWithError
{
    PUBLISH(((( {SBEventPostLayout *event = [SBEventPostLayout new]; event;}))));
    
    NSString *eid = @"This Is the Test eid.";
    SBEventReportConversion *event = [SBEventReportConversion new];
    event.eid = eid;
    event.conversionType = kSBConversionSuccessful;
    event.error = [NSError new];
    PUBLISH(event);
    
    NSArray <SBMReportConversion> *conversions = [self.sut conversions];
    BOOL hasReportConversion = NO;
    
    for (SBMReportConversion *reportConversion in conversions)
    {
        if ([reportConversion.eid isEqualToString:eid] &&
            reportConversion.type == kSBConversionSuccessful)
        {
            hasReportConversion = YES;
            break;
        }
    }
    
    XCTAssertFalse(hasReportConversion);
}


@end
