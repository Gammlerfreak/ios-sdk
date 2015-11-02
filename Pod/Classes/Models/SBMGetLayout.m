//
//  SBMGetLayout.m
//  Pods
//
//  Created by Andrei Stoleru on 26/10/15.
//
//

#import "SBMGetLayout.h"

#import "SBProtocolModels.h"
#import "SBProtocolEvents.h"

#import <tolo/Tolo.h>

@implementation SBMGetLayout

- (void)checkCampaignsForBeacon:(SBMBeacon *)beacon trigger:(SBTriggerType)trigger {
    //
    BOOL shouldFire;
    //
    for (SBMAction *action in self.actions) {
        for (SBMBeacon *actionBeacon in action.beacons) {
            shouldFire = YES;
            if ([actionBeacon.fullUUID isEqualToString:beacon.fullUUID]) {
                if (trigger==action.trigger || action.trigger==kSBTriggerEnterExit) {
                    for (SBMTimeframe *time in action.timeframes) {
                        if (!isNull(time.start) && [now laterDate:time.start]==time.start) {
                            SBLog(@"❌ %@-%@",now,time.start);
                            shouldFire = NO;
                        }
                        //
                        if (!isNull(time.end) && [now earlierDate:time.end]==time.end) {
                            SBLog(@"❌ %@-%@",now,time.end);
                            shouldFire = NO;
                        }
                        //
                    }
                    //
                    if (action.sendOnlyOnce) {
                        if ([self campaignHasFired:action.eid]) {
                            SBLog(@"❌ Already fired");
                            shouldFire = NO;
                        }
                    }
                    //
                    SBCampaignAction *campaignAction = [SBCampaignAction new];
                    //
                    if (!isNull(action.deliverAt)) {
                        if ([action.deliverAt earlierDate:now]==action.deliverAt) {
                            SBLog(@"❌ Send at it's in the past");
                            shouldFire = NO;
                        } else {
                            SBLog(@"❌ Will deliver at: %@",action.deliverAt);
                            campaignAction.fireDate = action.deliverAt;
                        }
                    }
                    //
                    if (action.suppressionTime) {
                        NSTimeInterval previousFire = [self secondsSinceLastFire:beacon.fullUUID];
                        if (previousFire > 0 && previousFire < action.suppressionTime) {
                            SBLog(@"❌ Suppressed");
                            shouldFire = NO;
                        }
                    }
                    //
                    if (action.delay) {
                        campaignAction.fireDate = [NSDate dateWithTimeIntervalSinceNow:action.delay];
                        SBLog(@"🔵 Delayed %i",action.delay);
                    }
                    //
                    if (shouldFire) {
                        campaignAction.eid = action.eid;
                        campaignAction.subject = action.content.subject;
                        campaignAction.body = action.content.body;
                        campaignAction.payload = action.content.payload;
                        campaignAction.trigger = trigger;
                        campaignAction.type = action.type;
                        //
                        campaignAction.beacon = beacon;
                        //
                        SBLog(@"🔥 Campaign \"%@\"",campaignAction.subject);
                        //
                        PUBLISH((({
                            SBEventPerformAction *event = [SBEventPerformAction new];
                            event.campaign = campaignAction;
                            event;
                        })));
                    }
                    
                    //
                } else {
                    SBLog(@"❌ TRIGGER %lu-%lu",(unsigned long)trigger,(unsigned long)action.trigger);
                }
            } else {
                //
            }
        }
    }
    //
}

#pragma mark - Helper methods

- (BOOL)campaignHasFired:(NSString*)eid {
    return !isNull([keychain stringForKey:eid]);
}

- (NSTimeInterval)secondsSinceLastFire:(NSString*)fullUUID {
    //
    NSString *lastFireString = [keychain stringForKey:fullUUID];
    if (isNull(lastFireString)) {
        return -1;
    }
    //
    NSDate *lastFireDate = [dateFormatter dateFromString:lastFireString];
    return [now timeIntervalSinceDate:lastFireDate];
}

@end
