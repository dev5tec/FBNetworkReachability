//
//  Copyright CELLANT Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef enum {
	kNetworkReachableUninitialization = 0,
	kNetworkReachableNon,
	kNetworkReachableWiFi,
	kNetworkReachableWWAN
} NetworkReachabilityConnectionMode;

#define NetworkReachabilityChangedNotification @"NetworkReachabilityChangedNotification"

@interface MLNetworkReachability : NSObject {

	SCNetworkReachabilityRef reachability_;
	NetworkReachabilityConnectionMode connectionMode_;
}

@property (assign) NetworkReachabilityConnectionMode connectionMode;

+ (MLNetworkReachability*)networkReachabilityWithHostname:(NSString *)hostname;

- (BOOL)isReachable;

@end
