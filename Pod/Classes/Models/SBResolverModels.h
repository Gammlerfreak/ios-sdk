//
//  SBResolverModels.h
//  Pods
//
//  Created by Andrei Stoleru on 08/09/15.
//
//

#import <Foundation/Foundation.h>

#import <JSONModel/JSONModel.h>

#import "SBMSession.h"

#import "SBMBeacon.h"

typedef enum : NSUInteger {
    kSBTriggerEnter=1,
    kSBTriggerExit=2,
    kSBTriggerEnterExit=3,
} SBTriggerType;

//@protocol SBMContent @end // -> SBMAction
@interface SBMContent : JSONModel
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *body;
@property (strong, nonatomic) NSDictionary <Optional> *payload;
@property (strong, nonatomic) NSString *url;
// these properties are not in the JSON, they will be filled by the SDK to send to the host app
//@property (strong, nonatomic) NSDate *fireDate;
//@property (nonatomic) int       *type;
//@property (strong, nonatomic) NSString  *eid;
@end

@protocol SBMTimeframe @end
@interface SBMTimeframe : JSONModel
@property (strong, nonatomic) NSDate <Optional> *start;
@property (strong, nonatomic) NSDate <Optional> *end;
@end

@protocol SBMAction @end // -> SBMCampaign
@interface SBMAction : JSONModel
@property (strong, nonatomic) NSString *eid;
@property (nonatomic) SBTriggerType trigger;
@property (strong, nonatomic) NSArray *beacons;
@property (nonatomic) int suppressionTime;
@property (nonatomic) int delay; //
@property (nonatomic) BOOL reportImmediately; // when true flush the history immediately
@property (nonatomic) BOOL sendOnlyOnce; //
@property (strong, nonatomic) NSDate *deliverAt;
@property (strong, nonatomic) SBMContent *content;
@property (nonatomic) int type;
@property (strong, nonatomic) NSArray <SBMTimeframe> *timeframes;
@property (strong, nonatomic) NSString *typeString;
//
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *pid;
@property (strong, nonatomic) NSDate *dt;
@end

@protocol SBMGetLayout @end
@interface SBMGetLayout : JSONModel
@property (strong, nonatomic) NSArray <NSString*> *accountProximityUUIDs;
@property (nonatomic) int reportTrigger;
@property (strong, nonatomic) NSArray <SBMAction> *actions;
@property (nonatomic) BOOL currentVersion;
@property (strong, nonatomic) NSArray <SBMAction> *instantActions;
@end

// Post objects

@protocol SBMReportAction @end
@interface SBMReportAction : JSONModel
@property (strong, nonatomic) NSString  *eid;
@property (strong, nonatomic) NSString  *pid;
@property (strong, nonatomic) NSDate    *dt;
@property (nonatomic) int trigger;
@property (strong, nonatomic) NSString  *location;
@property (strong, nonatomic) NSDictionary *reaction;
@end

@protocol SBMPostLayout @end
@interface SBMPostLayout : JSONModel
@property (strong, nonatomic) NSDate *deviceTimestamp;
@property (strong, nonatomic) NSArray <SBMMonitorEvent> *events; // of SBMMonitorEvent type?
@property (strong, nonatomic) NSArray <SBMReportAction> *actions; // of SBMReportAction type?
@end
