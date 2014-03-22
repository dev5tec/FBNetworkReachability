Network Reachability Detector
=============================

You can use FBNetworkReachabilty class to get network reachability on iOS device.


Usage
-----

(1) Getting connection mode

	FBNetworkReachabilityConnectionMode mode =
		[FBNetworkReachability sharedInstance].connectionMode;
	switch (mode) {
		case FBNetworkReachableNon:
		break;

		case FBNetworkReachableWiFi:
		break;

		case FBNetworkReachableWWAN:
		break;
	}

You can get the connection mode from 'connectionMode' property.


(3) Checking reachability

	if ([FBNetworkReachability sharedInstance].reachable) {
		:
	}

You can get the rechability flag.


(4) Using notification

FBNetworkReachability posts FBNetworkReachabilityDidChangeNotification when the network reachability changs. To use the notification you can write the event driven code.

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(didChangeNetworkReachability:)
		       name:FBNetworkReachabilityDidChangeNotification
		     object:nil];
	[[FBNetworkReachability sharedInstance] startNotifier];

	- (void)didChangeNetworkReachability:(NSNotification*)notification
	{
		FBNetworkReachabiity* network = [notification object];
			:
	}


Features
--------
- FBNetworkReachabiity does not work in background.
- FBNetworkReachabiity posts the newest network rechability change.
- The instances has same URL points to same instance internally.
- Thread-safe
- Requirements: SystemConfiguration.framework

Customize
---------

(non)


Installation
-----------

You should copy below files to your projects.

	FBNetworkReachability.h
	FBNetworkReachability.m
	SystemConfiguration.framework


License
-------
see LICENSE file

