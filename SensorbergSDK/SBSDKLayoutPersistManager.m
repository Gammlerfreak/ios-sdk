//
//  SBSDKLayoutPersistManger.m
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

#define SBSDKLayoutValidUntilStamp @"SensorBergSDKLayoutValidUntil"
#define SBSDKLayout @"SensorBergSDKLayout"
#define SBSDKHistory @"SensorBergSDKHistory"

#define SBSDKDeliveryHistory @"deliveryHistory"
#define SBSDKSuppressHistory @"suppressHistory"
#define SBSDKDeliverOnceHistory @"deliverOnceHistory"
#define SBSDKSyncHistory @"syncHistory"

#define SBSDKHistoryActionIDKey @"eid"
#define SBSDKHistoryBeaconIDKey @"pid"
#define SBSDKHistoryDeliveryTimeKey @"dt"

#define SBSDKLayoutActionsKey @"actions"
#define SBSDKSyncDeviceTimeStampKey @"deviceTimestamp"

#define layoutUpdateTimeInterval  2.0   //

#define defaultValidTimeframe 86400

#import "SBSDKLayoutPersistManager.h"

@implementation SBSDKEventUpdatedActions
@end

@interface SBSDKLayoutPersistManager ()

@property (nonatomic,strong) NSDate* layoutValidUntilDate;
@property (nonatomic,strong) NSDictionary* currentLayout;

@property (nonatomic,strong) NSDateFormatter* dateFormater;

@property (strong) NSMutableDictionary* syncHistory;
@property (strong) NSMutableArray* deliveryHistory;
@property (strong) NSMutableArray* suppressHistory;
@property (strong) NSMutableArray* sendOnlyOnceHistory;

@property (strong) GBStorageController *storage;

@end

@implementation SBSDKLayoutPersistManager

@synthesize layoutValidUntilDate = _layoutValidUntilDate;
@synthesize currentLayout = _currentLayout;

+ (SBSDKLayoutPersistManager *)sharedInstance
{
    static SBSDKLayoutPersistManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    // fix for concurrency issue
    if (sharedInstance) return sharedInstance;
    
    dispatch_once(&pred, ^{
        sharedInstance = [SBSDKLayoutPersistManager alloc];
        sharedInstance = [sharedInstance init];
        
        sharedInstance.dateFormater = [[NSDateFormatter alloc] init];
        sharedInstance.dateFormater.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        sharedInstance.dateFormater.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        
        [sharedInstance loadPersistStore];
        
    });
    
    return sharedInstance;
}

- (void)dealloc
{
    UNREGISTER();
}

- (void) loadPersistStore {
    if (!_storage) {
        _storage = [GBStorageController sharedControllerForNamespace:[[NSBundle mainBundle] bundleIdentifier]];
    }
    
    if (_storage[SBSDKLayoutValidUntilStamp] && [_storage[SBSDKLayoutValidUntilStamp] isKindOfClass:[NSDate class]]) {
        
        if (_storage[SBSDKLayout] && [_storage[SBSDKLayout] isKindOfClass:[NSData class]]) {
            
            NSData *layoutData = _storage[SBSDKLayout];
            
            self.currentLayout = [NSKeyedUnarchiver unarchiveObjectWithData:layoutData];

            self.layoutValidUntilDate = _storage[SBSDKLayoutValidUntilStamp];
        }
    } else {
        
        self.layoutValidUntilDate = Nil;
        self.currentLayout = Nil;
        
        // make shure we remove unreadable defaults
        
        [_storage removePermanently:SBSDKLayout];
        [_storage removePermanently:SBSDKLayoutValidUntilStamp];
        
        [_storage saveAll];
    }
    
    if (_storage[SBSDKHistory] && [_storage[SBSDKHistory] isKindOfClass:[NSData class]]) {
        
        NSData *deliveredActionsData = _storage[SBSDKHistory];
        
        NSDictionary* history = [NSKeyedUnarchiver unarchiveObjectWithData:deliveredActionsData];
        
        if ([history objectForKey:SBSDKDeliveryHistory] && [[history objectForKey:SBSDKHistory] isKindOfClass:[NSArray class]]) {
            self.deliveryHistory = [NSMutableArray arrayWithArray:[history objectForKey:SBSDKDeliveryHistory]];
        } else {
            self.deliveryHistory = [NSMutableArray new];
        }
        
        if ([history objectForKey:SBSDKDeliverOnceHistory] && [[history objectForKey:SBSDKDeliverOnceHistory] isKindOfClass:[NSArray class]]) {
            self.sendOnlyOnceHistory = [NSMutableArray arrayWithArray:[history objectForKey:SBSDKDeliverOnceHistory]];
        } else {
            self.sendOnlyOnceHistory = [NSMutableArray new];
        }
        
        if ([history objectForKey:SBSDKSuppressHistory] && [[history objectForKey:SBSDKSuppressHistory] isKindOfClass:[NSArray class]]) {
            self.suppressHistory = [NSMutableArray arrayWithArray:[history objectForKey:SBSDKSuppressHistory]];
        } else {
            self.suppressHistory = [NSMutableArray new];
        }
        
        if ([history objectForKey:SBSDKSyncHistory] && [[history objectForKey:SBSDKSyncHistory] isKindOfClass:[NSDictionary class]]) {
            self.syncHistory = [NSMutableDictionary dictionaryWithDictionary:[history objectForKey:SBSDKSyncHistory]];
        } else {
            self.syncHistory = [NSMutableDictionary new];
        }
        
    } else {
        self.deliveryHistory = [NSMutableArray new];
        self.sendOnlyOnceHistory = [NSMutableArray new];
        self.suppressHistory = [NSMutableArray new];
    }
}

- (void) setPersistLayout:(NSDictionary*)layout withMaxAgeInterval:(NSNumber*) maxAgeTimeInterval {

    @synchronized(self) {
        
        self.currentLayout = [layout copy];
        
        self.layoutValidUntilDate = [NSDate dateWithTimeIntervalSinceNow:maxAgeTimeInterval.doubleValue];
        
        [_storage setObject:self.layoutValidUntilDate forKeyedSubscript:SBSDKLayoutValidUntilStamp];
        
        [_storage setObject:[NSKeyedArchiver archivedDataWithRootObject:self.currentLayout] forKeyedSubscript:SBSDKLayout];
        
        [_storage saveAll];

        [self cleanUpHistory];

        SBSDKEventUpdatedActions *eventUpdate = [SBSDKEventUpdatedActions new];
        eventUpdate.beaconAction = self.currentLayout[SBSDKLayoutActionsKey];
        PUBLISH(eventUpdate);
    }
}

- (NSDictionary*) persistLayout {
    
    if ([self.layoutValidUntilDate timeIntervalSinceNow] > 0) {
        
        return self.currentLayout;
    }
    
    return Nil;
}

- (void) registerScanEvent:(SBSDKBeacon*)beacon {
    
    //
    
}

- (void) addDeliveredActionsToHistorie:(NSArray*)beaconActions forBeaconIdentifier:(NSString*)beaconIdentifier{
    
    @synchronized(self) {
        
        NSString* nowString = [self.dateFormater stringFromDate:[NSDate date]];
        
        for (SBSDKBeaconAction* deliveredAction in beaconActions) {
            
            NSMutableDictionary* historieEntry = [NSMutableDictionary new];
            
            if (deliveredAction.actionID != nil) {
                
                [historieEntry setObject:deliveredAction.actionID forKey:SBSDKHistoryActionIDKey];
                [historieEntry setObject:nowString forKey:SBSDKHistoryDeliveryTimeKey];
                // do lowercase and remove '-' to confirm to BE format ..
                beaconIdentifier = [beaconIdentifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
                [historieEntry setObject:[beaconIdentifier lowercaseString] forKey:SBSDKHistoryBeaconIDKey];
                
                [self.deliveryHistory addObject:historieEntry];
                
                if ([deliveredAction.sendOnlyOnce boolValue]) {
                    [self.sendOnlyOnceHistory addObject:historieEntry];
                }
                
                if (deliveredAction.suppressionTime.doubleValue > 0) {
                    [self.suppressHistory addObject:historieEntry];
                }
            }
        }
        
    }
    
    [self persistContent];
  
}

- (NSMutableDictionary*)historyToSync {
    
    @synchronized(self) {
     
        NSMutableArray* currentHistoryToSync = [self.deliveryHistory mutableCopy];
        
        NSMutableDictionary* historyDump;
        
        NSString *syncHistoryID;
        
        NSString* nowString = [self.dateFormater stringFromDate:[NSDate date]];
        
        if (self.syncHistory.count > 0) {
            
            // grap a old dump ... append new entrys ...and resend
            
            syncHistoryID = [self.syncHistory.allKeys firstObject];
            
            //NSMutableDictionary* obsoleteHistoryDump = [self.syncHistory objectForKey:syncHistoryID];
            
            NSMutableArray* oldHistoryEntrys = [NSMutableArray arrayWithArray:[historyDump objectForKey:SBSDKLayoutActionsKey]];

            [currentHistoryToSync addObjectsFromArray:oldHistoryEntrys];
            
            historyDump = [NSMutableDictionary dictionaryWithObjectsAndKeys:currentHistoryToSync,SBSDKLayoutActionsKey,syncHistoryID, SBSDKSyncHistroyIDKey,nowString,SBSDKSyncDeviceTimeStampKey,nil];
            
            
        } else {

            // create new dump
            
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            syncHistoryID = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
            CFRelease(uuid);
            
            
            historyDump = [NSMutableDictionary dictionaryWithObjectsAndKeys:currentHistoryToSync,SBSDKLayoutActionsKey,syncHistoryID, SBSDKSyncHistroyIDKey,nowString,SBSDKSyncDeviceTimeStampKey,nil];
            
        }
        
        [self.syncHistory setObject:historyDump forKey:syncHistoryID];
        
        [self.deliveryHistory removeAllObjects];
        
        [self persistContent];
        
        [historyDump setObject:[NSArray new] forKey:@"events"];
        
        return [historyDump mutableCopy];
    }
}

- (void) historySyncSuccessWithIdentifier:(NSString*)syncHistoryID {
    
    // a history dump with identifier is successfully sync with BE, so we delete this dump
    
    [self.syncHistory removeObjectForKey:syncHistoryID];
    
    [self persistContent];
}

- (void) persistContent {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @synchronized(self) {
            
            NSDictionary* history = [NSDictionary dictionaryWithObjectsAndKeys:self.deliveryHistory,SBSDKDeliveryHistory,self.suppressHistory,SBSDKSuppressHistory,self.sendOnlyOnceHistory,SBSDKDeliverOnceHistory,self.syncHistory,SBSDKSyncHistory, nil];
            
            [_storage setObject:[NSKeyedArchiver archivedDataWithRootObject:history] forKeyedSubscript:SBSDKHistory];
            
            [_storage saveAll];
        }
    });
}


- (BOOL) shouldDeliverOnlyOnceBeaconAction:(SBSDKBeaconAction*)beaconAction {
    
    NSString* actionID = beaconAction.actionID;
    
    for (NSDictionary* historyEntry in self.sendOnlyOnceHistory) {
        if ([[historyEntry objectForKey:SBSDKHistoryActionIDKey] isEqualToString:actionID]) {
            return FALSE;
        }
    }
    return TRUE;
}


- (BOOL) shouldSuppressBeaconAction:(SBSDKBeaconAction*)beaconAction {
    
    NSString* actionID = beaconAction.actionID;
    

    
    NSMutableArray* obsoleteSuppressionAction = [NSMutableArray new];
    
    for (NSDictionary* historyEntry in self.suppressHistory) {
        if ([[historyEntry objectForKey:SBSDKHistoryActionIDKey] isEqualToString:actionID]) {
            
            if ([historyEntry objectForKey:SBSDKHistoryDeliveryTimeKey] && [[historyEntry objectForKey:SBSDKHistoryDeliveryTimeKey] isKindOfClass:[NSString class]]) {
                
                NSDate* lastDelieveryTime = [self.dateFormater dateFromString:[historyEntry objectForKey:SBSDKHistoryDeliveryTimeKey]];
                
                if ([lastDelieveryTime timeIntervalSinceNow] > (-1 * beaconAction.suppressionTime.doubleValue)) {
                    // delivery suppressed
                    return TRUE;
                } else {
                    // remove old action from history
                    [obsoleteSuppressionAction addObject:historyEntry];
                }
            }
        }
    }
    
    // clean up obsolete suppression history entry
    [self.suppressHistory removeObjectsInArray:obsoleteSuppressionAction];
    
    return FALSE;
}

- (void) cleanUpHistory {
    
    // clean up historie from obsolete beacon actions
    // remove obsolete action from suppress and sendOnce historie
    
    NSArray* allActions = self.currentLayout[SBSDKLayoutActionsKey];
    
    NSMutableArray* currentActionIds = [NSMutableArray arrayWithCapacity:allActions.count];
    
    for (NSDictionary* action in allActions) {
        
        [currentActionIds addObject:[action objectForKey:SBSDKHistoryActionIDKey]];
    }
    
    NSMutableArray* obsoleteActions = [NSMutableArray new];
    
    for (NSDictionary* historyItem in self.sendOnlyOnceHistory) {
    
        NSString* historyItemActionID = [historyItem objectForKey:SBSDKHistoryActionIDKey];
        
        if ([currentActionIds containsObject:historyItemActionID]) {
            [obsoleteActions addObject:historyItem];
        }
    }
    
    [self.sendOnlyOnceHistory removeObjectsInArray:obsoleteActions];
    
    [obsoleteActions removeAllObjects];
    
    for (NSDictionary* historyItem in self.suppressHistory) {
        
        NSString* historyItemActionID = [historyItem objectForKey:SBSDKHistoryActionIDKey];
        
        if (![currentActionIds containsObject:historyItemActionID]) {
            [obsoleteActions addObject:historyItem];
        }
    }
    
    [self.suppressHistory removeObjectsInArray:obsoleteActions];
    
}

@end
