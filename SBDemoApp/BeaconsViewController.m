//
//  BeaconsViewController.m
//  SensorbergSDK
//
//  Created by Andrei Stoleru on 12/01/16.
//  Copyright © 2016 Sensorberg GmbH. All rights reserved.
//

#import "BeaconsViewController.h"

#import <SensorbergSDK/SensorbergSDK.h>

#import <SensorbergSDK/NSString+SBUUID.h>

#import <tolo/Tolo.h>

@interface BeaconsViewController () {
    NSMutableDictionary *beacons;
}

@end

static NSString *const kReuseIdentifier = @"beaconCell";

@implementation BeaconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    REGISTER();
    
    beacons = [NSMutableDictionary new];
    
    [[SBManager sharedManager] setApiKey:@"248b403be4d9041aca3c01bcb886f876d8fc1768379993f7c7e3b19f41526a2a" delegate:self];
//    [[SBManager sharedManager] setApiKey:nil delegate:self];
    [[SBManager sharedManager] requestLocationAuthorization];
//    [[SBManager sharedManager] requestBluetoothAuthorization];
//    [[SBManager sharedManager] requestNotificationsAuthorization];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = @"Beacons";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return beacons.allValues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReuseIdentifier forIndexPath:indexPath];
    
    cell.imageView.image = nil;
    
    if ([beacons.allValues[indexPath.row] isKindOfClass:[SBMBeacon class]]) {
        SBMBeacon *beacon = beacons.allValues[indexPath.row];
        NSString *proximityUUID = [[NSString hyphenateUUIDString:beacon.uuid] uppercaseString];
        if ([[SensorbergSDK defaultBeaconRegions] valueForKey:proximityUUID]) {
            cell.textLabel.text = [[SensorbergSDK defaultBeaconRegions] valueForKey:proximityUUID];
        } else {
            cell.textLabel.text = proximityUUID;
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Major:%i  Minor:%i", beacon.major, beacon.minor];
        
        
    } else if ([beacons.allValues[indexPath.row] isKindOfClass:[CBPeripheral class]]) {
        CBPeripheral *p = beacons.allValues[indexPath.row];
        
        cell.textLabel.text = p.name ? p.name : @"No Name";
        cell.detailTextLabel.text = p.identifier.UUIDString;
        
        cell.imageView.image = [self imageFromText:@"BLE"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SensorbergSDK events

#pragma mark SBEventLocationAuthorization
SUBSCRIBE(SBEventLocationAuthorization) {
    if (event.locationAuthorization==SBLocationAuthorizationStatusAuthorized) {
        //
    }
}

SUBSCRIBE(SBEventBluetoothAuthorization) {
    NSLog(event.bluetoothAuthorization==SBBluetoothOn ? @"Bluetooth ON" : @"Bluetooth Off");
}

SUBSCRIBE(SBEventNotificationsAuthorization) {
    if (!event.notificationsAuthorization) {
        [[SBManager sharedManager] stopMonitoring];
    }
}

#pragma mark SBEventRegionEnter
SUBSCRIBE(SBEventRegionEnter) {
    [beacons setValue:event.beacon forKey:event.beacon.fullUUID];
    //    NSLog(@"Enter region: %@ (M:%i m:%i)", [NSString hyphenateUUIDString:event.beacon.uuid], event.beacon.major, event.beacon.minor);
    [self.tableView reloadData];
}

#pragma mark SBEventRegionExit
SUBSCRIBE(SBEventRegionExit) {
    [beacons setValue:nil forKey:event.beacon.fullUUID];
    //    NSLog(@"Exit region: %@ (M:%i m:%i)", [NSString hyphenateUUIDString:event.beacon.uuid], event.beacon.major, event.beacon.minor);
    [self.tableView reloadData];
}

#pragma mark SBEventRangedBeacon
SUBSCRIBE(SBEventRangedBeacon) {
    [beacons setValue:event.beacon forKey:event.beacon.fullUUID];
}

#pragma mark SBEventPerformAction
SUBSCRIBE(SBEventPerformAction) {
    //    NSLog(@"Campaign fired: %@ (%@)",event.campaign.subject, event.campaign.body);
}

#pragma mark - 

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

-(UIImage *)imageFromText:(NSString *)text
{
    CGSize size  = [text sizeWithAttributes:nil];
    
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    
    [text drawAtPoint:CGPointZero withAttributes:nil];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
