//
//  MainViewController.h
//  Application9
//
//  Created by Iain Buchanan on 08/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
    UILabel *myIPLabel;
    UITextField *peerField;
    UISegmentedControl *instChoice;
}
@property (nonatomic, retain) IBOutlet UILabel *myIPLabel;
@property (nonatomic, retain) IBOutlet UITextField *peerField;
@property (nonatomic, retain) IBOutlet UISegmentedControl *instChoice;


- (IBAction)showInfo:(id)sender;


@end
