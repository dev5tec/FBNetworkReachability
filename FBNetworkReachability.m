//
// Copyright (c) 2011 Five-technology Co.,Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "FBNetworkReachability.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>

static NSMutableDictionary* networkReachabilities_;


@interface FBNetworkReachability()
@property (assign) NetworkReachabilityConnectionMode connectionMode;
@property (copy) NSString* ipaddress;
- (BOOL)_startNotifier;
- (void)_stopNotifier;
@end


@implementation FBNetworkReachability

@synthesize connectionMode;
@synthesize ipaddress;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initialization and deallocation
//------------------------------------------------------------------------------
- (id)initWithHostname:(NSString*)hostname
{
    self = [super init];
	if (self) {
		reachability_=
			SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
											[hostname UTF8String]);
		self.connectionMode = kNetworkReachableUninitialization;		
		[self _startNotifier];
	}
	return self;
}

- (void) dealloc
{
    [self _stopNotifier];
	CFRelease(reachability_);
	[super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private
//------------------------------------------------------------------------------
- (NSString*)_getIPAddressWiFilEnabled:(BOOL)wifiEnabled
{
    // priority:
    // (1) WiFi "en0", "en1", ...
    // (2) WWAN "pdp_ip0", ...
    //
    // memo:
    // name=pdp_ip0
    // addr=126.202.8.39

	struct ifaddrs * addrs;
	const struct ifaddrs * cursor;
    
    NSString* addressStringForWiFi = nil;
    NSString* addressStringForWWAN = nil;
	
	if (getifaddrs(&addrs) == 0) {
		cursor = addrs;
		while (cursor != NULL) {
			if (cursor->ifa_addr->sa_family == AF_INET
				&& (cursor->ifa_flags & IFF_LOOPBACK) == 0) {
				NSString *name =
				[NSString stringWithUTF8String:cursor->ifa_name];
				
                // found the WiFi adapter
				if ([name isEqualToString:@"en0"] ||	// iPhone
					[name isEqualToString:@"en1"]) {	// Simulator (Mac)
					addressStringForWiFi = [NSString stringWithUTF8String:
                                            inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
				} else {
                    addressStringForWWAN = [NSString stringWithUTF8String:
                                            inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                }
			}
			
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
    if (addressStringForWiFi) {
        return addressStringForWiFi;
    }
    if (!wifiEnabled) {
        return addressStringForWWAN;
    }
    return nil;
}

// return
//	 0: no connection
//	 1: celluar connection
//	 2: wifi connection
- (NetworkReachabilityConnectionMode)_getConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
	BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
	if (isReachable && !needsConnection) {
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
			return kNetworkReachableWWAN;
		}
		
		if ([self _getIPAddressWiFilEnabled:YES]) {
			return kNetworkReachableWiFi;
		}
		
	}
	return kNetworkReachableNon;	
}


- (void)_updateConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	self.connectionMode = [self _getConnectionModeWithFlags:flags];
    self.ipaddress = [self _getIPAddressWiFilEnabled:NO];
    NSLog(@"ip: %@", self.ipaddress);
}

// call back function
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
	
	FBNetworkReachability* noteObject = (FBNetworkReachability*)info;
	[noteObject _updateConnectionModeWithFlags:flags];
    NSLog(@"[INFO] Connection mode changed: %@", noteObject);

	[[NSNotificationCenter defaultCenter]
		postNotificationName:FBNetworkReachabilityDidChangeNotification object:noteObject];

	[myPool release];
}

- (BOOL)_startNotifier
{
	BOOL ret = NO;
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	if(SCNetworkReachabilitySetCallback(reachability_, ReachabilityCallback, &context))
	{
		if(SCNetworkReachabilityScheduleWithRunLoop(
													reachability_, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
		{
			ret = YES;
		}
	}
	return ret;
}	

- (void)_stopNotifier
{
	if(reachability_!= NULL)
	{
		SCNetworkReachabilityUnscheduleFromRunLoop(reachability_, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark API
//------------------------------------------------------------------------------
+ (FBNetworkReachability*)networkReachabilityWithHostname:(NSString*)hostname
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkReachabilities_ = [[NSMutableDictionary alloc] init];
    });
    FBNetworkReachability* networkReachability = [networkReachabilities_ objectForKey:hostname];
    if (networkReachability == nil) {
        networkReachability = [[self alloc] initWithHostname:hostname];
        [networkReachabilities_ setObject:networkReachability forKey:hostname];
        [networkReachability release];
    }
    return networkReachability;
}

- (NSString*)IPAddress
{
    return [self _getIPAddressWiFilEnabled:NO];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Properties
//------------------------------------------------------------------------------
- (BOOL)reachable
{
    if (self.connectionMode == kNetworkReachableWiFi ||
        self.connectionMode == kNetworkReachableWWAN) {
        return YES;
    } else {
        return NO;
    }
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark etc
//------------------------------------------------------------------------------
- (NSString*)description
{
	NSString* desc = nil;
	
	switch (self.connectionMode) {
		case kNetworkReachableUninitialization:
			desc = @"Not initialized";
			break;
            
		case kNetworkReachableNon:
			desc = @"Not available";
			break;
			
		case kNetworkReachableWWAN:
			desc = @"WWAN";
			break;
			
		case kNetworkReachableWiFi:
			desc = @"WiFi";
			break;
			
	}
	return desc;
}


@end
