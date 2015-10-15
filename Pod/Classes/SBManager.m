//
//  SBManager.m
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

#import "SBManager.h"

#import "SBResolver.h"
#import "SBLocation.h"
#import "SBBluetooth.h"
#import "SBAnalytics.h"

#import "SBResolverEvents.h"
#import "SBLocationEvents.h"
#import "SBBluetoothEvents.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

@interface SBManager () {
    SBMGetLayout *layout;
    //
    double ping;
}

@property (readonly, nonatomic) SBResolver      *apiClient;
@property (readonly, nonatomic) SBLocation      *locClient;
@property (readonly, nonatomic) SBBluetooth     *bleClient;
@property (readonly, nonatomic) SBAnalytics     *anaClient;

@end

@implementation SBManager

NSString *SBAPIKey = nil;
NSString *SBResolverURL = nil;

static SBManager * _sharedManager;

static dispatch_once_t once;

+ (instancetype)sharedManager {
    if (!_sharedManager) {
        //
        dispatch_once(&once, ^ {
            _sharedManager = [super new];
            //
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:5];
            //
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:APIDateFormat];
            //
            keychain = [UICKeyChainStore keyChainStoreWithService:[SBUtility applicationIdentifier]];
            keychain.accessibility = UICKeyChainStoreAccessibilityAlways;
            keychain.synchronizable = YES;
            //
            if (![SBUtility debugging]) {
                SBLog(@"Output to console.log");
                NSString *logPath = [kSBCacheFolder stringByAppendingPathComponent:@"console.log"];
                freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
            }
        });
        //
    }
    return _sharedManager;
}

- (void)resetSharedClient {
    // enforce main thread
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        [self performSelectorOnMainThread:@selector(resetSharedClient) withObject:nil waitUntilDone:NO];
        return;
    }
    //
    SBResolverURL = nil;
    //
    SBAPIKey = nil;
    //
    _sharedManager = nil;
    // we reset the dispatch_once_t to 0 (it's a long) so we can re-create the singleton instance
    once = 0;
    // we also reset the latency value to -1 (no connectivity)
    ping = -1;
    //
    [keychain removeAllItems];
    //
    UNREGISTER();
    [[Tolo sharedInstance] unsubscribe:_anaClient];
    [[Tolo sharedInstance] unsubscribe:_apiClient];
    [[Tolo sharedInstance] unsubscribe:_locClient];
    [[Tolo sharedInstance] unsubscribe:_bleClient];
    //
    _anaClient = nil;
    _apiClient = nil;
    _locClient = nil;
    _bleClient = nil;
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //
    PUBLISH([SBEventResetManager new]);
}

#pragma mark - Designated initializer

- (void)setupResolver:(NSString*)resolver apiKey:(NSString*)apiKey {
    //
    if (isNull(resolver)) {
        SBResolverURL = kSBDefaultResolver;
    } else {
        SBResolverURL = resolver;
    }
    //
    if (isNull(apiKey)) {
        SBAPIKey = kSBDefaultAPIKey;
    } else {
        SBAPIKey = apiKey;
    }
    //
    if (!_apiClient) {
        _apiClient = [[SBResolver alloc] initWithResolver:SBResolverURL apiKey:SBAPIKey];
        [[Tolo sharedInstance] subscribe:_apiClient];
    }
    //
    if (!_locClient) {
        _locClient = [SBLocation new];
        [[Tolo sharedInstance] subscribe:_locClient];
    }
    //
    if (!_bleClient) {
        _bleClient = [SBBluetooth new];
        [[Tolo sharedInstance] subscribe:_bleClient];
    }
    //
    if (!_anaClient) {
        _anaClient = [SBAnalytics new];
        [[Tolo sharedInstance] subscribe:_anaClient];
    }
    //
    UNREGISTER();
    REGISTER();
    // set the latency to a negative value before the first ping
    ping = -1;
    [_apiClient ping];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingWithOptions:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    //
    SBLog(@"SBManager initialized");
}

#pragma mark - Resolver methods

- (SBMGetLayout *)currentLayout {
    return layout;
}

- (void)requestLayout {
    [_apiClient requestLayout];
}

- (double)resolverLatency {
    return ping;
}

- (void)requestResolverStatus {
    [_apiClient ping];
}

SUBSCRIBE(SBEventPing) {
    if (!event.error) {
        ping = event.latency;
    }
}

#pragma mark - Location methods

- (void)requestLocationAuthorization {
    if (_locClient) {
        [_locClient requestAuthorization];
    }
}

- (SBLocationAuthorizationStatus)locationAuthorization {
    return [_locClient authorizationStatus];
}

#pragma mark - Bluetooth methods

- (void)requestBluetoothAuthorization {
    if (_bleClient) {
        [_bleClient requestAuthorization];
    }
}

- (SBBluetoothStatus)bluetoothAuthorization {
    return [_bleClient authorizationStatus];
}

SUBSCRIBE(SBEventBluetoothAuthorization) {
    if (event.bluetoothAuthorization==SBBluetoothOn) {
        [self setupResolver:SBResolverURL apiKey:SBAPIKey];
    }
}

#pragma mark - Status

- (SBManagerAvailabilityStatus)availabilityStatus {
    //
    switch (self.bleClient.authorizationStatus) {
        case SBBluetoothOff: {
            return SBManagerAvailabilityStatusBluetoothRestricted;
            break;
        }
        default: {
            break;
        }
    }
    
    switch (self.backgroundAppRefreshStatus) {
        case SBManagerBackgroundAppRefreshStatusRestricted:
        case SBManagerBackgroundAppRefreshStatusDenied:
            return SBManagerAvailabilityStatusBackgroundAppRefreshRestricted;
            
        default:
            break;
    }
    
    switch (self.locClient.authorizationStatus) {
        case SBLocationAuthorizationStatusNotDetermined:
        case SBLocationAuthorizationStatusUnimplemented:
        case SBLocationAuthorizationStatusRestricted:
        case SBLocationAuthorizationStatusDenied:
        case SBLocationAuthorizationStatusUnavailable:
            return SBManagerAvailabilityStatusAuthorizationRestricted;
            
        default:
            break;
    }
    
    if (!self.apiClient.isConnected) {
        return SBManagerAvailabilityStatusConnectionRestricted;
    }
    //
    return SBManagerAvailabilityStatusFullyFunctional;
}

- (SBManagerBackgroundAppRefreshStatus)backgroundAppRefreshStatus {
    //
    UIBackgroundRefreshStatus status = [UIApplication sharedApplication].backgroundRefreshStatus;
    //
    switch (status) {
        case UIBackgroundRefreshStatusRestricted:
            return SBManagerBackgroundAppRefreshStatusRestricted;
            
        case UIBackgroundRefreshStatusDenied:
            return SBManagerBackgroundAppRefreshStatusDenied;
            
        case UIBackgroundRefreshStatusAvailable:
            return SBManagerBackgroundAppRefreshStatusAvailable;
            
        default:
            break;
    }
    
    return SBManagerBackgroundAppRefreshStatusAvailable;
}

- (void)startMonitoring {
    if (layout && layout.accountProximityUUIDs) {
        //
        [self.locClient startMonitoring:layout.accountProximityUUIDs];
    }
}

- (void)startBackgroundMonitoring {
    [self.locClient startBackgroundMonitoring];
}

#pragma mark SBEventGetLayout
SUBSCRIBE(SBEventGetLayout) {
    if (event.error) {
        SBLog(@"* %@",event.error.localizedDescription);
        return;
    }
    //
    layout = event.layout;
    //
    [self startMonitoring];
}

#pragma mark SBEventPostLayout
SUBSCRIBE(SBEventPostLayout) {
    if (isNull(event.error)) {
        NSString *lastPostString = [dateFormatter stringFromDate:now];
        [keychain setString:lastPostString forKey:kPostLayout];
        //
        return;
    }
    SBLog(@"Error posting layout: %@",event.error);
}

#pragma mark SBEventLocationAuthorization
SUBSCRIBE(SBEventLocationAuthorization) {
    //
}

#pragma mark SBEventRangedBeacons
SUBSCRIBE(SBEventRangedBeacons) {
    //
}

#pragma mark SBEventRegionEnter
SUBSCRIBE(SBEventRegionEnter) {
    SBLog(@"> Enter region: %@",event.beacon.fullUUID);
    //
    SBTriggerType triggerType = kSBTriggerEnter;
    //
    [self checkCampaignsForUUID:event.beacon.fullUUID trigger:triggerType];
}

#pragma mark SBEventRegionExit
SUBSCRIBE(SBEventRegionExit) {
    SBLog(@"< Exit region: %@",event.beacon.fullUUID);
    //
    SBTriggerType triggerType = kSBTriggerExit;
    //
    [self checkCampaignsForUUID:event.beacon.fullUUID trigger:triggerType];
}

#pragma mark - Analytics

- (void)postHistory {
    NSString *lastPostString = [keychain stringForKey:kPostLayout];
    if (!isNull(lastPostString)) {
        NSDate *lastPostDate = [dateFormatter dateFromString:lastPostString];
        //
        if ([now timeIntervalSinceDate:lastPostDate]<kPostSuppression*5) {
            return;
        }
    }
    //
    SBMPostLayout *postData = [SBMPostLayout new];
    postData.events = [self.anaClient events];
    postData.deviceTimestamp = now;
    postData.actions = [self.anaClient actions];
    //
    if (postData.events.count && postData.actions.count) {
        [self.apiClient postLayout:postData];
    }
}

#pragma mark - Application lifecycle

- (void)applicationDidFinishLaunchingWithOptions:(NSNotification *)notification {
    SBLog(@"%s",__func__);
    //
    PUBLISH([SBEventApplicationLaunched new]);
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    SBLog(@"%s",__func__);
    //
    PUBLISH([SBEventApplicationActive new]);
    //
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    SBLog(@"%s",__func__);
    // fire an event instead
    [[SBManager sharedManager] startBackgroundMonitoring];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    SBLog(@"%s",__func__);
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    SBLog(@"%s",__func__);
}

#pragma mark - SDK Logic

- (void)checkCampaignsForUUID:(NSString *)fullUUID trigger:(SBTriggerType)trigger {
    //
    for (SBMAction *action in layout.actions) {
        for (SBMBeacon *beacon in action.beacons) {
            BOOL shouldFire = YES;
            if ([beacon.fullUUID isEqualToString:fullUUID]) {
                if (trigger==action.trigger || action.trigger==kSBTriggerEnterExit) {
                    for (SBMTimeframe *time in action.timeframes) {
                        if (!isNull(time.start) && [now laterDate:time.start]==time.start) {
                            SBLog(@"~ EARLY %@-%@",now,time.start);
                            shouldFire = NO;
                        }
                        //
                        if (!isNull(time.end) && [now earlierDate:time.end]==time.end) {
                            SBLog(@"~ LATE %@-%@",now,time.end);
                            shouldFire = NO;
                        }
                        //
                    }
                    //
                    if (action.sendOnlyOnce) {
                        if ([self campaignHasFired:action.eid]) {
                            SBLog(@"~ Already fired");
                            shouldFire = NO;
                        }
                    }
                    //
                    SBCampaignAction *campaignAction = [SBCampaignAction new];
                    //
                    if (!isNull(action.deliverAt)) {
                        if ([action.deliverAt earlierDate:now]==action.deliverAt) {
                            SBLog(@"~ Send at it's in the past");
                            shouldFire = NO;
                        } else {
                            SBLog(@"~ Will deliver at: %@",action.deliverAt);
                            campaignAction.fireDate = action.deliverAt;
                        }
                    }
                    //
                    if (action.suppressionTime) {
                        int previousFire = [self secondsSinceLastFire:fullUUID];
                        if (previousFire > 0 && previousFire < action.suppressionTime) {
                            SBLog(@"~ Suppressed");
                            shouldFire = NO;
                        }
                    }
                    //
                    if (action.delay) {
                        campaignAction.fireDate = [NSDate dateWithTimeIntervalSinceNow:action.delay];
                        SBLog(@"~ Delayed %i",action.delay);
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
                        campaignAction.beacon = [[SBMBeacon alloc] initWithString:fullUUID];
                        //
                        PUBLISH((({
                            //
                            SBEventPerformAction *event = [SBEventPerformAction new];
                            event.campaign = campaignAction;
                            event;
                            //
                        })));
                    }
                    
                    //
                } else {
                    SBLog(@"~ TRIGGER %lu-%lu",(unsigned long)trigger,(unsigned long)action.trigger);
                }
            }
        }
    }
    //
}

#pragma mark SBEventPerformAction
SUBSCRIBE(SBEventPerformAction) {
    //
    [keychain setString:[dateFormatter stringFromDate:now] forKey:event.campaign.eid];
}

#pragma mark SBEventApplicationActive
SUBSCRIBE(SBEventApplicationActive) {
    [self postHistory];
    //
}

#pragma mark - Helper methods

- (BOOL)campaignHasFired:(NSString*)eid {
    return !isNull([keychain stringForKey:eid]);
}

- (int)secondsSinceLastFire:(NSString*)fullUUID {
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
