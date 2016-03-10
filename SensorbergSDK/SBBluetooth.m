//
//  SBBluetooth.m
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

#import "SBBluetooth.h"

#import "SBInternalEvents.h"

#import "SensorbergSDK.h"

#import <tolo/Tolo.h>

@interface SBBluetooth() {
    CBCentralManager *manager;
    CBPeripheralManager *peripheralManager;
    
    NSMutableDictionary *peripherals;
    NSMutableDictionary *connections;
    NSMutableDictionary *scans;
    
    NSOperationQueue *queue;
    
    SBBluetoothStatus oldStatus;
    
    BOOL scanEh;
}

@end

@implementation SBBluetooth

#pragma mark - SBBluetooth

static SBBluetooth * _sharedManager;

static dispatch_once_t once;

+ (instancetype)sharedManager {
    if (!_sharedManager) {
        //
        dispatch_once(&once, ^ {
            _sharedManager = [[self alloc] init];
        });
        //
    }
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        peripherals = [NSMutableDictionary new];
        connections = [NSMutableDictionary new];
        scans = [NSMutableDictionary new];
        
        queue = [[NSOperationQueue alloc] init];
        queue.qualityOfService = NSQualityOfServiceUserInitiated;
        queue.maxConcurrentOperationCount = 1;
        
        scanEh = NO;
    }
    return self;
}


#pragma mark - External methods

- (void)requestAuthorization {
    if (!manager) {
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue.underlyingQueue];
    }
    if (!peripheralManager) {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)startAdvertising:(NSString *)proximityUUID major:(int)major minor:(int)minor name:(NSString*)name {
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID]
                                                                     major:major
                                                                     minor:minor
                                                                identifier:name];
    [peripheralManager startAdvertising:[region peripheralDataWithMeasuredPower:nil]];
}

- (void)stopAdvertising {
    [peripheralManager stopAdvertising];
}

- (void)startServiceScan:(NSArray *)services {
    if (!manager) {
        [self requestAuthorization];
    }
    //
    [manager scanForPeripheralsWithServices:services options:nil];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    [scans removeObjectForKey:peripheral.identifier.UUIDString];
    //
    [manager connectPeripheral:peripheral options:nil];
}

- (NSString *)titleForCharacteristic:(CBCharacteristic*)c {
    int cValue;
    [c.UUID.data getBytes:&cValue length:c.UUID.data.length];
    //
    switch (CFSwapInt16(cValue)) {
        case iBKSHardware:
            return @"Manufacturer";
            break;
        case iBKSRevision:
            return @"Hardware version";
            break;
        case iBKSSerial:
            return @"Serial number";
            break;
        case iBKSVersion:
            return @"Firmware version";
            break;
        case iBKSUUID:
            return @"Proximity UUID";
            break;
        case iBKSMajor:
            return @"Major";
            break;
        case iBKSMinor:
            return @"Minor";
            break;
        case iBKSTxPwr:
            return @"TxPower";
            break;
        case iBKSCPwr:
            return @"Calibrated Power";
            break;
        case iBKSAdv:
            return @"Advertising interval";
            break;
        case iBKSCfg:
            return @"Configuration mode";
            break;
        case iBKSPwd:
            return @"Lock";
            break;
        case iBKSStatus:
            return @"Status";
            break;
        default:
            break;
    }
    return @"Title";
}

- (NSString*)valueForCharacteristic:(CBCharacteristic*)c {
    int cIdentifier;
    [c.UUID.data getBytes:&cIdentifier length:c.UUID.data.length];
    
    NSData *cValue = [c value];
    if (!cValue) {
        return @"";
    }
    //
    switch (CFSwapInt16(cIdentifier)) {
        case iBKSHardware:
        case iBKSRevision:
        case iBKSSerial:
        case iBKSVersion:
        {
            return [[NSString alloc] initWithData:cValue encoding:NSUTF8StringEncoding];
            break;
        }
        case iBKSUUID:
        {
            CBUUID *u = [CBUUID UUIDWithData:c.value];
            return [NSString stringWithFormat:@"%@", u.UUIDString];
            break;
        }
        case iBKSMajor:
        {
            int majorValue = 0;
            [cValue getBytes:&majorValue length:2];
            return [NSString stringWithFormat:@"%i",majorValue];
            break;
        }
        case iBKSMinor:
        {
            int minorValue = 0;
            [cValue getBytes:&minorValue length:2];
            return [NSString stringWithFormat:@"%i",minorValue];
            break;
        }
        case iBKSTxPwr:
        {
            int txValue = 0;
            [cValue getBytes:&txValue length:1];
            return [NSString stringWithFormat:@"%i",txValue];
            break;
        }
        case iBKSCPwr:
        {
            int cpwrValue = 0;
            [cValue getBytes:&cpwrValue length:1];
            return [NSString stringWithFormat:@"%i",cpwrValue];
            break;
        }
        case iBKSAdv:
        {
            int advValue = 0;
            [cValue getBytes:&advValue length:2];
            return [NSString stringWithFormat:@"%i",advValue];
            break;
        }
        case iBKSCfg:
            return @"Configuration mode";
            break;
        case iBKSPwd:
            return @"Lock";
            break;
        case iBKSStatus:
            return @"Status";
            break;
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@",c.UUID];
}

- (NSArray *)devices {
    NSMutableArray *temps = [NSMutableArray arrayWithArray:[peripherals allValues]];
    
    [temps sortUsingComparator:^NSComparisonResult(SBPeripheral *p1, SBPeripheral *p2) {
        if ([p1.peripheral.name isEqualToString:@"iBKS105"]) {
            return NSOrderedAscending;
        } else if ([p2.peripheral.name isEqualToString:@"iBKS105"]) {
            return NSOrderedDescending;
        }
        
        if ([p1.firstSeen earlierDate:p2.firstSeen]==p1.firstSeen) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    
    return temps;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(nonnull CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI {
    //
    BOOL connectable = [(NSNumber*)[advertisementData valueForKey:CBAdvertisementDataIsConnectable] boolValue];
    if (!connectable) {
        return;
    }
    //
    SBPeripheral *p = [peripherals valueForKey:peripheral.identifier.UUIDString];
    if (!p) {
        p = [SBPeripheral new];
        p.firstSeen = now;
        p.pid = peripheral.identifier.UUIDString;
        p.peripheral = peripheral;
        [p.peripheral setDelegate:self];
        if (scanEh) {
            if (!peripheral.name) {
                [scans setObject:p forKey:p.pid];
                [manager connectPeripheral:peripheral options:nil];
            }
        }
    }
    p.RSSI = RSSI;
    p.lastSeen = now;
    [peripherals setObject:p forKey:p.pid];
    //
    [self updateBeacons];
}

- (void)centralManager:(nonnull CBCentralManager *)central didConnectPeripheral:(nonnull CBPeripheral *)peripheral {
//    SBLog(@"%s",__func__);
    //
    if ([scans objectForKey:peripheral.identifier.UUIDString]) {
        [manager cancelPeripheralConnection:peripheral];
        [connections removeObjectForKey:peripheral.identifier.UUIDString];
        [scans removeObjectForKey:peripheral.identifier.UUIDString];
    } else {
        SBPeripheral *p = [peripherals objectForKey:peripheral.identifier.UUIDString];
        if (!p) {
            p = [connections objectForKey:peripheral.identifier.UUIDString];
        }
        if (p) {
            [connections setObject:p forKey:p.pid];
            PUBLISH((({
                SBEventDeviceConnected *event = [SBEventDeviceConnected new];
                event.device = p;
                event;
            })));
        }
    }
    //
    [self updatePeripheral:peripheral];
    [self updateBeacons];
    //
    [peripheral discoverServices:nil];
}

- (void)centralManager:(nonnull CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
    //
    SBPeripheral *p = [connections objectForKey:peripheral.identifier.UUIDString];
    //
    if ([scans objectForKey:peripheral.identifier.UUIDString]) {
        [scans removeObjectForKey:peripheral.identifier.UUIDString];
        [peripherals removeObjectForKey:peripheral.identifier.UUIDString];
        [connections removeObjectForKey:peripheral.identifier.UUIDString];
    } else {
        //
        if (!p) {
            p = [peripherals objectForKey:peripheral.identifier.UUIDString];
        }
        if (p) {
            [connections setObject:p forKey:p.pid];
        }
    }
    //
    PUBLISH((({
        SBEventDeviceLost *event = [SBEventDeviceLost new];
        event.device = p;
        event;
    })));
    //
    [self updatePeripheral:peripheral];
    [self updateBeacons];
}

- (void)centralManager:(nonnull CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
    //
    [scans removeObjectForKey:peripheral.identifier.UUIDString];
    [peripherals removeObjectForKey:peripheral.identifier.UUIDString];
    [connections removeObjectForKey:peripheral.identifier.UUIDString];
}

- (void)centralManager:(nonnull CBCentralManager *)central willRestoreState:(nonnull NSDictionary<NSString *,id> *)dict {
//    SBLog(@"%s",__func__);
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    SBBluetoothStatus newStatus = [self authorizationStatus];
    if (oldStatus==newStatus) {
        return;
    }
    oldStatus = newStatus;
    PUBLISH(({
        SBEventBluetoothAuthorization *event = [SBEventBluetoothAuthorization new];
        event.bluetoothAuthorization = oldStatus;
        event;
    }));
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
    
    if (error) {
        return;
    }
    //
    [self updatePeripheral:peripheral];
    [self updateBeacons];
    //
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    //
    PUBLISH((({
        SBEventServicesUpdated *event = [SBEventServicesUpdated new];
        event.device = [connections objectForKey:peripheral.identifier.UUIDString];
        event;
    })));
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(nonnull CBService *)service error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    if (error) {
        return;
    }
    //
    [self updatePeripheral:peripheral];
    [self updateBeacons];
    //
    PUBLISH((({
        SBEventCharacteristicsUpdate *event = [SBEventCharacteristicsUpdate new];
        event.device = [connections objectForKey:peripheral.identifier.UUIDString];
        //
        event;
    })));
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
    
    SBEventCharacteristicsUpdate *event = [SBEventCharacteristicsUpdate new];
    event.characteristic = characteristic;
    event.error = error;
    PUBLISH(event);
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didUpdateValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
    
    SBEventCharacteristicWrite *event = [SBEventCharacteristicWrite new];
    event.characteristic = characteristic;
    event.error = error;
    PUBLISH(event);
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didWriteValueForDescriptor:(nonnull CBDescriptor *)descriptor error:(nullable NSError *)error {
    SBLog(@"%s",__func__);
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (error) {
        //
        return;
    }
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didReadRSSI:(nonnull NSNumber *)RSSI error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
    if (error) {
        return;
    }
    //
    [self updatePeripheral:peripheral];
    [self updateBeacons];
}

- (void)peripheralDidUpdateName:(nonnull CBPeripheral *)peripheral {
//    SBLog(@"%s",__func__);
    [self updatePeripheral:peripheral];
    [self updateBeacons];
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didModifyServices:(nonnull NSArray<CBService *> *)invalidatedServices {
//    SBLog(@"%s",__func__);
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(nonnull CBPeripheralManager *)peripheral {
    
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral willRestoreState:(nonnull NSDictionary<NSString *,id> *)dict {
    
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral didAddService:(nonnull CBService *)service error:(nullable NSError *)error {
//    SBLog(@"%s",__func__);
}

- (void)peripheralManagerDidStartAdvertising:(nonnull CBPeripheralManager *)peripheral error:(nullable NSError *)error {
    SBEventBluetoothEmulation *event = [SBEventBluetoothEmulation new];
    event.error = error;
    PUBLISH(event);
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral central:(nonnull CBCentral *)central didSubscribeToCharacteristic:(nonnull CBCharacteristic *)characteristic {
//    SBLog(@"%s",__func__);
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral central:(nonnull CBCentral *)central didUnsubscribeFromCharacteristic:(nonnull CBCharacteristic *)characteristic {
    
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral didReceiveReadRequest:(nonnull CBATTRequest *)request {
    
}

- (void)peripheralManager:(nonnull CBPeripheralManager *)peripheral didReceiveWriteRequests:(nonnull NSArray<CBATTRequest *> *)requests {
    
}

#pragma mark - Bluetooth status

- (SBBluetoothStatus)authorizationStatus {
    if (manager.state==CBCentralManagerStateUnknown) {
        return SBBluetoothUnknown;
    } else if (manager.state<CBCentralManagerStatePoweredOn) {
        return SBBluetoothOff;
    }
    //
    //    [manager scanForPeripheralsWithServices:nil options:nil];
    //
    return SBBluetoothOn;
    //
}

#pragma mark - Internal methods


- (void)updateBeacons {
    for (SBPeripheral *p in peripherals.allValues) {
        if (p.lastSeen && ABS([p.lastSeen timeIntervalSinceNow])>10) {
            [peripherals removeObjectForKey:p.pid];
            [connections removeObjectForKey:p.pid];
        }
    }
    //
    PUBLISH([SBEventDeviceUpdated new]);
}

- (void)updatePeripheral:(CBPeripheral*)peripheral {
    if (!peripheral) {
        return;
    }
    SBPeripheral *p = [peripherals objectForKey:peripheral.identifier.UUIDString];
    if (!p) {
        return;
    }
    //
    p.peripheral = peripheral;
    [p.peripheral setDelegate:self];
    p.lastSeen = now;
    //
    if (p.peripheral.state==CBPeripheralStateConnected) {
        [connections setObject:p forKey:p.pid];
    }
    //
    [peripherals setObject:p forKey:p.pid];
}

- (NSArray *)defaultServices {
    return @[@"180F", // battery service
             @"1805", // current time
             @"180A", // device information
             @"1800", // generic access
             @"1801", // generic attribute
             @"1812", // hid
             @"1821", // indoor positioning
             @"1819", // location and navigation
             @"1804", // tx power
             @"181C", // user data
             @"FFF0", // ble
             @"FFF1", // uuid
             @"FFF5", // transmission power
             @"2A23", // extension
             ];
}

@end
