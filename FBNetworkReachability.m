//
//  Copyright CELLANT Corp. All rights reserved.
//

#import "MLNetworkReachability.h"
#import "MLUtility.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>

@interface MLNetworkReachability()
- (BOOL)startNotifier;
@end

static NSMutableDictionary* networkReachabilities_;

@implementation MLNetworkReachability

@synthesize connectionMode = connectionMode_;

- (id)initWithHostname:(NSString*)hostname
{
    self = [super init];
	if (self) {
		reachability_=
			SCNetworkReachabilityCreateWithName(kCFAllocatorDefault,
											[hostname UTF8String]);
		self.connectionMode = kNetworkReachableUninitialization;		
		[self startNotifier];
	}
	return self;
}

+ (MLNetworkReachability*)networkReachabilityWithHostname:(NSString*)hostname
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkReachabilities_ = [[NSMutableDictionary alloc] init];
    });
    MLNetworkReachability* networkReachability = [networkReachabilities_ objectForKey:hostname];
    if (networkReachability == nil) {
        networkReachability = [[self alloc] initWithHostname:hostname];
        [networkReachabilities_ setObject:networkReachability forKey:hostname];
        [networkReachability release];
    }
    return networkReachability;
}

- (void) dealloc
{
	CFRelease(reachability_);
	[super dealloc];
}


- (NSString*)getWiFiIPAddress
{
	BOOL success;
	struct ifaddrs * addrs;
	const struct ifaddrs * cursor;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
			if (cursor->ifa_addr->sa_family == AF_INET
				&& (cursor->ifa_flags & IFF_LOOPBACK) == 0) {
				NSString *name =
				[NSString stringWithUTF8String:cursor->ifa_name];
				
				 // found the WiFi adapter
				if ([name isEqualToString:@"en0"] ||	// iPhone
					[name isEqualToString:@"en1"]) {	// Simulator (Mac)
					NSString* addressString = [NSString stringWithUTF8String:
							inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
					freeifaddrs(addrs);
					return addressString;
				}
			}
			
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	return NULL;
}


// return
//	 0: no connection
//	 1: celluar connection
//	 2: wifi connection
- (NetworkReachabilityConnectionMode)getConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
	BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
	if (isReachable && !needsConnection) {
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
			return kNetworkReachableWWAN;
		}
		
		if ([self getWiFiIPAddress]) {
			return kNetworkReachableWiFi;
		}
		
	}
	return kNetworkReachableNon;	
}

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

- (BOOL)isReachable
{
    if (self.connectionMode == kNetworkReachableWiFi ||
        self.connectionMode == kNetworkReachableWWAN) {
        return YES;
    } else {
        return NO;
    }
}


- (void)updateConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	self.connectionMode = [self getConnectionModeWithFlags:flags];
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
	
	MLNetworkReachability* noteObject = (MLNetworkReachability*)info;
	[noteObject updateConnectionModeWithFlags:flags];
	[MLUtility logType:kMLLogTypeInfo
			   message:[NSString stringWithFormat:
						@"Connection mode changed: %@", noteObject]];

	[[NSNotificationCenter defaultCenter]
		postNotificationName:NetworkReachabilityChangedNotification object:noteObject];

	[myPool release];
}

- (BOOL)startNotifier
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

- (void) stopNotifier
{
	if(reachability_!= NULL)
	{
		SCNetworkReachabilityUnscheduleFromRunLoop(reachability_, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}

@end
