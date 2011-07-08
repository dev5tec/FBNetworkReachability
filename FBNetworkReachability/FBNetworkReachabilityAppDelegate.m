//
//  FBNetworkReachabilityAppDelegate.m
//  FBNetworkReachability
//
//  Created by Hiroshi Hashiguchi on 11/05/10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBNetworkReachabilityAppDelegate.h"
#import "FBNetworkReachability.h"

@implementation FBNetworkReachabilityAppDelegate


@synthesize window=_window;

@synthesize tableView = tableView_;
@synthesize history;

- (void)_didChangeNetworkReachability:(FBNetworkReachability*)networkReachability
{
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [networkReachability description], @"ConnectionMode",
                          networkReachability.ipaddress, @"IPAddress",
                          [NSDate date], @"Timestamp",
                          nil];
    [self.history insertObject:dict atIndex:0];
    [self.tableView reloadData];    
}

- (void)_didChangeConnectionMode:(NSNotification*)notification
{
    NSLog(@"%@", notification);
    [self _didChangeNetworkReachability:[notification object]];
}

- (void)_didFireTimer:(NSTimer*)timer
{
    FBNetworkReachability* networkReachability = [FBNetworkReachability sharedInstance];
    [networkReachability refresh];
    [self _didChangeNetworkReachability:networkReachability];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    self.history = [NSMutableArray array];

    // [1] test for async
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didChangeConnectionMode:) 
                                                 name:FBNetworkReachabilityDidChangeNotification
                                               object:nil];

    [[FBNetworkReachability sharedInstance] startNotifier];
    
    // [2] test for sync
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(_didFireTimer:)
                                   userInfo:nil
                                    repeats:YES];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.history count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    static NSString *cellIdentifier = @"Cell";
    cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:cellIdentifier] autorelease];
        
    }
    NSDictionary* dict = [self.history objectAtIndex:indexPath.row];
    NSString* ipaddress = [dict objectForKey:@"IPAddress"];
    NSString* title = nil;
    if (ipaddress) {
        title = [NSString stringWithFormat:@"%@ [%@]",
                 [dict objectForKey:@"ConnectionMode"],
                 ipaddress];
    } else {
        title = [dict objectForKey:@"ConnectionMode"];
    }
    cell.textLabel.text = title;
    cell.detailTextLabel.text = [[dict objectForKey:@"Timestamp"] description];
    
    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate

@end
