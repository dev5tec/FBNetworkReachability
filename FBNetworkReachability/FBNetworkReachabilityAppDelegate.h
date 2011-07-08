//
//  FBNetworkReachabilityAppDelegate.h
//  FBNetworkReachability
//
//  Created by Hiroshi Hashiguchi on 11/05/10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBNetworkReachability;
@interface FBNetworkReachabilityAppDelegate : NSObject <UIApplicationDelegate, UITableViewDelegate, UITableViewDataSource> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) NSMutableArray* history;

@end
