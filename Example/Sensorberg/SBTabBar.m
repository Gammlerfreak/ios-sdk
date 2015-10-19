//
//  SBTabBar.m
//  Sensorberg
//
//  Created by Andrei Stoleru on 22/09/15.
//  Copyright © 2015 Sensorberg. All rights reserved.
//

#import "SBTabBar.h"

#import <Sensorberg/SensorbergSDK.h>

#import "SBAppDelegate.h"

//#define kBaseURL    @"https://resolver.sensorberg.com/"
//#define kApiKey     @"248b403be4d9041aca3c01bcb886f876d8fc1768379993f7c7e3b19f41526a2a"
//
//#define kBaseURL    @"https://staging-resolver.sensorberg.com/"
//#define kApiKey     @"0000000000000000000000000000000000000000000000000000000000000000"


static NSString *kSBActionKey = @"action";

@implementation SBDemoNotificationEvent
@end

@interface SBTabBar () {
    
}

@end

@implementation SBTabBar

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    REGISTER();
    //
    NSArray *vcs = self.viewControllers;
    for (UINavigationController *navViewController in vcs)
    {
        [[navViewController.viewControllers objectAtIndex:0] view];
    }
    //
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Shake event

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.subtype==UIEventSubtypeMotionShake) {
        if (alert) {
            return;
        }
        //
        alert = [[UIAlertView alloc] initWithTitle:@"Reset SBManager"
                                           message:@"Do you want to reset the SBManager instance?"
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"YES", nil];
        //
        [alert show];
        //
        //
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
            NSLog(@"cancel");
        }
            break;
        case 1:
        {
            [[SBManager sharedManager] resetSharedClient];
            //
            [[SBManager sharedManager] setupResolver:[[NSUserDefaults standardUserDefaults] objectForKey:kSBResolver] apiKey:[[NSUserDefaults standardUserDefaults] objectForKey:kSBAPIKey]];
            [[SBManager sharedManager] requestLocationAuthorization];
        }
            break;
        default:
            break;
    }
    //
    alert = nil;
}

#pragma mark - SBManagerDelegate

SUBSCRIBE(SBEventPerformAction) {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (event.campaign.fireDate) {
        notification.fireDate = event.campaign.fireDate;
    } else {
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    }
    notification.alertTitle = event.campaign.subject;
    notification.alertBody = event.campaign.body;
    notification.alertAction = [NSString stringWithFormat:@"%@",event.campaign.payload];
    notification.userInfo = @{kSBActionKey:event.toJSONString};
    //
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

SUBSCRIBE(SBEventLocationAuthorization) {
    //
}

SUBSCRIBE(SBEventBluetoothAuthorization) {
    //
}

#pragma mark - Internal events

SUBSCRIBE(SBDemoNotificationEvent) {
    if (event.notification.userInfo) {
        NSString *action = [event.notification.userInfo valueForKey:kSBActionKey];
        //
        UIAlertView *notif = [[UIAlertView alloc] initWithTitle:@"Notification" message:action delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [notif show];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
