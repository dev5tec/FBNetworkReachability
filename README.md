Network Reachability Detector
=============================

You can use FBNetworkReachabilty class to get network reachability on iOS device.


Usage
-----

(1) Initialization

	FBNetworkReachability* network =
		[FBNetworkReachability networkReachabilityWithHostname:@"http://xcatsan.com/"];

To get an instance you must pass a valid URL.


(2) Getting connection mode

	FBNetworkReachabilityConnectionMode mode = network.connectionMode;
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

	if (network.reachable) {
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
MIT

Copyright (c) 2011 Hiroshi Hashiguchi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

