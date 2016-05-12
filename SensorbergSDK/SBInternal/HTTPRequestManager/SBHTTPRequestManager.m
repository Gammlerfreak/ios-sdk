//
//  SBHTTPRequestManager.m
//  WhiteLabel
//
//  Created by ParkSanggeon on 27/04/16.
//  Copyright © 2016 Sensorberg GmbH. All rights reserved.
//

#import "SBHTTPRequestManager.h"
#import "SBEvent.h"

#import <tolo/Tolo.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#pragma mark - Constants

typedef void (^SBNetworkReachabilityStatusBlock)(SBNetworkReachability status);

static const void * SBNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void SBNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

static void SBPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, SBNetworkReachabilityStatusBlock block) {

    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    SBNetworkReachability status = SBNetworkReachabilityUnknown;
    if (isNetworkReachable == NO) {
        status = SBNetworkReachabilityNone;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0)
    {
        status = SBNetworkReachabilityViaWWAN;
    }
#endif
    else
    {
        status = SBNetworkReachabilityViaWiFi;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block)
        {
            block(status);
        }
        
        PUBLISH((({
            SBEventReachabilityEvent *event = [SBEventReachabilityEvent new];
            event.reachable = (status == SBNetworkReachabilityViaWWAN || status == SBNetworkReachabilityViaWiFi);
            event;
        })));
    });
}

static void SBNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    SBPostReachabilityStatusChange(flags, (__bridge SBNetworkReachabilityStatusBlock)info);
}

#pragma mark - SBHTTPRequestManager
#pragma mark - Internal

@interface SBHTTPRequestManager ()

@property (nonatomic, strong) NSOperationQueue * _Nonnull operationQueue;
@property (readwrite, nonatomic, assign) SBNetworkReachability reachabilityStatus;
@property (readwrite, nonatomic, strong) id networkReachability;

@end


#pragma mark -

@implementation SBHTTPRequestManager

#pragma mark - Static Interfaces

+ (instancetype _Nonnull)sharedManager
{
    static dispatch_once_t once;
    static SBHTTPRequestManager *_sharedManager = nil;
    
    dispatch_once(&once, ^{
        _sharedManager = [SBHTTPRequestManager new];
        
    });
    
    return _sharedManager;
}

#pragma mark - Instance Life Cycle

- (instancetype)init
{
    if (self = [super init])
    {
        REGISTER();
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;
        
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&address);
        _networkReachability = CFBridgingRelease(reachability);
        _reachabilityStatus = SBNetworkReachabilityUnknown;
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        
        [self startMonitoring];
    }
    
    return self;
}

- (void)dealloc
{
    UNREGISTER();
    [self stopMonitoring];
}

#pragma mark - Public Interfaces

- (void)getDataFromURL:(nonnull NSURL *)URL
          headerFields:(nullable NSDictionary *)header
              useCache:(BOOL)useCache
            completion:(void (^)(NSData * __nullable data, NSError * __nullable error))completionHandler;
{
    [self.operationQueue addOperationWithBlock:^{
        
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
        if (useCache)
        {
            configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
        }
        else
        {
            configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        }
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL];
        URLRequest.HTTPMethod = @"GET";
        [self setHeaderFields:header forURLRequest:URLRequest];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (completionHandler)
            {
                completionHandler(data, error);
            }
        }];
        [task resume];
    }];
}

- (void)postData:(NSData *)data URL:(nonnull NSURL *)URL
    headerFields:(NSDictionary *)header
      completion:(void (^)(NSData * __nullable data, NSError * __nullable error))completionHandler
{
    [self.operationQueue addOperationWithBlock:^{
        
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration defaultSessionConfiguration] copy];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        
        NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL];
        URLRequest.HTTPMethod = @"POST";
        URLRequest.HTTPBody = data;
        [self setHeaderFields:header forURLRequest:URLRequest];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:URLRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (completionHandler)
            {
                completionHandler(data, error);
            }
        }];
        [task resume];
    }];
}

#pragma mark - Private Interfaces

- (void)setHeaderFields:(nonnull NSDictionary *)header forURLRequest:(nonnull NSMutableURLRequest *)URLRequest
{
    if (header && [header isKindOfClass:[NSDictionary class]])
    {
        for (NSString *key in header.allKeys)
        {
            id valueForKey = header[key];
            if ([valueForKey isKindOfClass:[NSString class]]) {
                [URLRequest setValue:valueForKey forHTTPHeaderField:key];
            }
        }
    }
}

#pragma mark - Network Reachability

- (BOOL)isReachable
{
    return self.reachabilityStatus == SBNetworkReachabilityViaWWAN || self.reachabilityStatus == SBNetworkReachabilityViaWiFi;
}

- (void)startMonitoring
{
    [self stopMonitoring];
    
    if (!self.networkReachability)
    {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    SBNetworkReachabilityStatusBlock callback = ^(SBNetworkReachability status)
    {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.reachabilityStatus = status;
        strongSelf.operationQueue.suspended = [strongSelf isReachable] ? NO : YES;
    };
    
    id networkReachability = self.networkReachability;
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, SBNetworkReachabilityRetainCallback, SBNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback((__bridge SCNetworkReachabilityRef)networkReachability, SBNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop((__bridge SCNetworkReachabilityRef)networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags((__bridge SCNetworkReachabilityRef)networkReachability, &flags)) {
            SBPostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring
{
    if (!self.networkReachability)
    {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop((__bridge SCNetworkReachabilityRef)self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

@end

#endif
