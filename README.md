# Sensorberg

[![CI Status](http://img.shields.io/travis/tagyro/Sensorberg.svg?style=flat)](https://travis-ci.org/tagyro/Sensorberg)
[![Version](https://img.shields.io/cocoapods/v/Sensorberg.svg?style=flat)](http://cocoapods.org/pods/Sensorberg)
[![License](https://img.shields.io/cocoapods/l/Sensorberg.svg?style=flat)](http://cocoapods.org/pods/Sensorberg)
[![Platform](https://img.shields.io/cocoapods/p/Sensorberg.svg?style=flat)](http://cocoapods.org/pods/Sensorberg)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

To use the SDK:

1. [[SBManager sharedManager] setupResolver:**resolverURL** apiKey:**apiKey**]
2. [[SBManager sharedManager] requestLocationAuthorization];
3. [[SBManager sharedManager] getLayout];

## Requirements

## Installation

Sensorberg is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Sensorberg"
```

## Author

[Sensorberg](https://sensorberg.com)

## License

Sensorberg is available under the MIT license. See the LICENSE file for more info.
