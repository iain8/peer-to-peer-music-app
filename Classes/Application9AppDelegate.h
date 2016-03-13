//
//  Application9AppDelegate.h
//  Application9
//
//  Created by Iain Buchanan on 08/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface Application9AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
    NSString *firstPeer;
    NSString *inst;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;
@property (nonatomic, retain) NSString *firstPeer;
@property (nonatomic, retain) NSString *inst;

@end

