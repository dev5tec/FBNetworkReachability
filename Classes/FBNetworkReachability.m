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

@interface FBNetworkReachability()
{
    SCNetworkReachabilityRef _reachability;
}
@property (assign) FBNetworkReachabilityConnectionMode connectionMode;
@end


@implementation FBNetworkReachability
@synthesize connectionMode = _connectionMode;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initialization and deallocation
//------------------------------------------------------------------------------
- (id)init
{
    return [self initWithHostName:@"google.com"];
}

- (id)initWithHostName:(NSString*)hostName
{
    self = [super init];
    if (self) {
        _reachability =
        SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
        
        self.connectionMode = FBNetworkReachableUninitialization;
        
        [self refresh];
    }
    return self;
}


- (void) dealloc
{
    [self stopNotifier];
	if (_reachability) {
		CFRelease(_reachability);
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private
//------------------------------------------------------------------------------

// return
//	 0: no connection
//	 1: celluar connection
//	 2: wifi connection
- (FBNetworkReachabilityConnectionMode)_getConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
	BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
	if (isReachable && !needsConnection) {
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
			return FBNetworkReachableWWAN;
		}
        return FBNetworkReachableWiFi;
	}
	return FBNetworkReachableNon;	
}


- (void)_updateConnectionModeWithFlags:(SCNetworkReachabilityFlags)flags
{
	self.connectionMode = [self _getConnectionModeWithFlags:flags];
}

// call back function
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	@autoreleasepool {
        FBNetworkReachability* noteObject = (__bridge FBNetworkReachability*)info;
        [noteObject _updateConnectionModeWithFlags:flags];
        NSLog(@"[INFO] Connection mode changed: %@ [%x]", noteObject, flags);
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:FBNetworkReachabilityDidChangeNotification object:noteObject];
    }
}

- (BOOL)startNotifier
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:FBNetworkReachabilityDidChangeNotification
                      object:self];
    
	BOOL ret = NO;
	SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	if(SCNetworkReachabilitySetCallback(_reachability, ReachabilityCallback, &context))
	{
		if(SCNetworkReachabilityScheduleWithRunLoop(
													_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
		{
			ret = YES;
		}
	}
	return ret;
}	

- (void)stopNotifier
{
	if(_reachability!= NULL)
	{
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark API
//------------------------------------------------------------------------------
FBNetworkReachability* _sharedInstance = nil;

+ (FBNetworkReachability*)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (void)refresh
{
    SCNetworkReachabilityFlags flags = 0;
    SCNetworkReachabilityGetFlags(_reachability, &flags);
    [self _updateConnectionModeWithFlags:flags];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Properties
//------------------------------------------------------------------------------
- (BOOL)reachable
{
    if (self.connectionMode == FBNetworkReachableWiFi ||
        self.connectionMode == FBNetworkReachableWWAN) {
        return YES;
    } else {
        return NO;
    }
}

- (FBNetworkReachabilityConnectionMode)connectionMode
{
    if (_connectionMode == FBNetworkReachableUninitialization) {
        [self refresh];
    }
    @synchronized (self) {
        return _connectionMode;
    }
}

- (void)setConnectionMode:(FBNetworkReachabilityConnectionMode)connectionMode
{
    @synchronized (self) {
        _connectionMode = connectionMode;
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
		case FBNetworkReachableUninitialization:
			desc = @"Not initialized";
			break;
            
		case FBNetworkReachableNon:
			desc = @"Not available";
			break;
			
		case FBNetworkReachableWWAN:
			desc = @"WWAN";
			break;
			
		case FBNetworkReachableWiFi:
			desc = @"WiFi";
			break;
			
	}
	return desc;
}


@end
