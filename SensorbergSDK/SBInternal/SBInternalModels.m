//
//  SBInternalModels.m
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

#import <tolo/Tolo.h>

#import "SBInternalModels.h"

#import "SensorbergSDK.h"

#import "SBUtility.h"

#import "SBEvent.h"

@implementation SBInternalModels

@end

@implementation SBMGetLayout

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (void)checkCampaignsForBeacon:(SBMBeacon *)beacon trigger:(SBTriggerType)trigger {
    
    NSDate *now = [NSDate date];
    
    for (SBMAction *action in self.actions) {
        for (SBMBeacon *actionBeacon in action.beacons) {
            if ([actionBeacon.fullUUID isEqualToString:beacon.fullUUID] == NO)
            {
                continue;
            }
            if (trigger!= action.trigger && action.trigger != kSBTriggerEnterExit)
            {
                SBLog(@"🔕 TRIGGER %lu-%lu",(unsigned long)trigger,(unsigned long)action.trigger);
                continue;
            }
            
            if (action.timeframes && [self campaignIsInTimeframes:action.timeframes] == NO) {
                continue;
            }
            //
            if (action.sendOnlyOnce && [self campaignHasFired:action.eid]) {
                SBLog(@"🔕 Already fired");
                continue;
            }

            if (!isNull(action.deliverAt) && [action.deliverAt earlierDate:now]==action.deliverAt) {
                SBLog(@"🔕 Send at it's in the past");
                continue;
            }
            
            NSTimeInterval previousFire = [self secondsSinceLastFire:action.eid];
            if (action.suppressionTime &&
                (previousFire > 0 && previousFire < action.suppressionTime)) {
                SBLog(@"🔕 Suppressed");
                continue;
            }
            
            [self fireAction:action forBeacon:beacon withTrigger:trigger];
        }
    }
    //
}

#pragma mark - Helper methods

- (BOOL)campaignHasFired:(NSString*)eid {
    return !isNull([keychain stringForKey:eid]);
}

- (NSTimeInterval)secondsSinceLastFire:(NSString*)eid {
    //
    NSString *lastFireString = [keychain stringForKey:eid];
    if (isNull(lastFireString)) {
        return -1;
    }
    //
    NSDate *lastFireDate = [dateFormatter dateFromString:lastFireString];
    return [[NSDate date] timeIntervalSinceDate:lastFireDate];
}

- (BOOL)campaignIsInTimeframes:(NSArray <SBMTimeframe> *)timeframes {
    
    BOOL afterStart = NO;
    BOOL beforeFinish = NO;
    
    NSDate *currentTime = [NSDate date];
    
    for (SBMTimeframe *time in timeframes) {
        
        afterStart = NO;
        beforeFinish = NO;
        
        if (isNull(time.start) || (!isNull(time.start) && [currentTime earlierDate:time.start]==time.start)) {
            SBLog(@"🔕 %@-%@",currentTime,time.start);
            afterStart = YES;
        }
        //
        if (isNull(time.end) || (!isNull(time.end) && [currentTime laterDate:time.end]==time.end)) {
            SBLog(@"🔕 %@-%@",currentTime,time.end);
            beforeFinish = YES;
        }
        //
        if (afterStart && beforeFinish) {
            return YES;
        }
    }
    return (afterStart && beforeFinish);
}

- (void)fireAction:(SBMAction *)action forBeacon:(SBMBeacon *)beacon withTrigger:(SBTriggerType)trigger
{
    SBMCampaignAction *campaignAction = [self campainActionWithAction:action beacon:beacon trigger:trigger];
    SBLog(@"🔔 Campaign \"%@\"",campaignAction.subject);
    [keychain setString:[dateFormatter stringFromDate:[NSDate date]] forKey:action.eid];
    //
    SBEventPerformAction *event = [SBEventPerformAction new];
    event.campaign = campaignAction;
    //
    PUBLISH(event);
    //
    if (action.reportImmediately) {
        PUBLISH([SBEventReportHistory new]);
    }
}

- (SBMCampaignAction *)campainActionWithAction:(SBMAction *)action beacon:(SBMBeacon *)beacon trigger:(SBTriggerType)trigger
{
    SBMCampaignAction *campaignAction = [SBMCampaignAction new];
    campaignAction.eid = action.eid;
    campaignAction.subject = action.content.subject;
    campaignAction.body = action.content.body;
    campaignAction.payload = action.content.payload;
    campaignAction.url = action.content.url;
    campaignAction.trigger = trigger;
    campaignAction.type = action.type;
    
    if (!isNull(action.deliverAt))
    {
        campaignAction.fireDate = action.deliverAt;
    }
    
    if (action.delay) {
        campaignAction.fireDate = [NSDate dateWithTimeIntervalSinceNow:action.delay];
        SBLog(@"🕓 Delayed %i",action.delay);
    }
    
    campaignAction.beacon = beacon;
    
    return campaignAction;
}

@end

emptyImplementation(SBMMonitorEvent)

@implementation SBMSession

- (instancetype)initWithUUID:(NSString*)UUID
{
    self = [super init];
    if (self) {
        NSDate *now = [NSDate date];
        _pid = UUID;
        _enter = [now copy];
        _lastSeen = [now copy];
    }
    return self;
}

@end

#pragma mark - Resolver models

@implementation SBMContent

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

emptyImplementation(SBMTimeframe)

@implementation SBMAction

- (BOOL)validate:(NSError *__autoreleasing *)error {
    NSMutableArray *newBeacons = [NSMutableArray new];
    for (NSString *uuid in self.beacons) {
        SBMBeacon *beacon = [[SBMBeacon alloc] initWithString:uuid];
        if (!isNull(beacon)) {
            [newBeacons addObject:beacon];
        }
    }
    self.beacons = [NSArray <SBMBeacon> arrayWithArray:newBeacons];
    return [super validate:error];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation SBMReportAction

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation SBMReportConversion

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

emptyImplementation(SBMPostLayout)


@implementation JSONValueTransformer (SBResolver)

- (NSDate *)NSDateFromNSString:(NSString*)string {
    return [dateFormatter dateFromString:string];
}

- (NSString*)JSONObjectFromNSDate:(NSDate *)date {
    return [dateFormatter stringFromDate:date];
}

@end