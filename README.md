# Sensorberg iOS SDK

> iOS SDK for handling iBeacon technology via the Sensorberg Beacon Management Platform. [http://www.sensorberg.com](http://www.sensorberg.com)

[![CI Status](https://travis-ci.org/sensorberg-dev/ios-sdk.svg?style=flat)](https://travis-ci.org/sensorberg-dev/ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/Sensorberg.svg?style=flat)](http://cocoapods.org/pods/SensorbergSDK)

## Try the Sensorberg SDK

Runing `pod try SensorbergSDK` in a terminal window will open the Sensorberg demo project.  
Select the `SBDemoApp` target and run on device.  


## Install

The easiest way to integrate the Sensorberg SDK is via [CocoaPods](http://cocoapods.org).  
To install it, simply add the following lines to your Podfile:  
`pod 'SensorbergSDK', '~> 2.4'`  

You can find a [full integration tutorial](http://sensorberg-dev.github.io/ios/) on our [developer portal](http://sensorberg-dev.github.io/).

## Notes

To use [portal.sensorberg.com](https://portal.sensorberg.com) you must update the `resolver` url.
Fire a `SBEventUpdateResolver` immediately after setting the API key:
```
PUBLISH(({
        SBEventUpdateResolver *updateEvent = [SBEventUpdateResolver new];
        updateEvent.baseURL = @"https://portal.sensorberg-cdn.com";
        updateEvent.interactionsPath    = @"/api/v2/sdk/gateways/{apiKey}/interactions.json";
        updateEvent.analyticsPath       = @"/api/v2/sdk/gateways/{apiKey}/analytics.json";
        updateEvent.settingsPath        = @"/api/v2/sdk/gateways/{apiKey}/settings.json?platform=ios";
        updateEvent.pingPath            = @"/api/v2/sdk/gateways/{apiKey}/active.json";
        updateEvent;
    }));
```
This is a temporary measure while our users migrate to the new portal.
The `{apiKey}` will be automatically replaced by the SDK.

The Sensorberg SDK uses an [EventBus](https://github.com/google/guava/wiki/EventBusExplained) for events dispatch. During setup, you pass the class instance that will receive the events as the delegate.

If you want to receive events in other class instances, simply call `REGISTER();` and subscribe to the events.

## Dependencies

The Sensorberg SDK requires iOS 8.0. Sensorberg SDK uses:

- [JSONModel](https://github.com/icanzilb/JSONModel) for JSON parsing  
- [UICKeyChainStore](https://github.com/kishikawakatsumi/UICKeyChainStore) for keychain access  
- [tolo](https://github.com/genzeb/tolo) for event communication  


## Documentation

To install the Sensorberg SDK docset, clone the repo and run the included script:  

```
$ cd your-project-directory  
$ chmod +x createDocs.sh  
$ ./createDocs.sh  
```
This will automatically create and install the docset in Xcode.
You can also build the SensorbergSDK_Documentation target which will generate and install the docset.

## Author

[Sensorberg GmbH](https://sensorberg.com)


## License

Sensorberg SDK is available under the MIT license. See the LICENSE file for more info.
