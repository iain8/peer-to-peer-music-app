//
//  MainViewController.m
//  Application9
//
//  Created by Iain Buchanan on 08/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "AppMain.h"
#import "Application9AppDelegate.h"

@implementation MainViewController
@synthesize peerField;
@synthesize instChoice;
@synthesize myIPLabel;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    myIPLabel.text = [AppMain initServerHost];
	[super viewDidLoad];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == peerField) {
        [peerField resignFirstResponder];
    }
    return YES;
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {
    
    if ([peerField.text length] == 0) {
        return;
    }
    
    Application9AppDelegate *appDelegate = (Application9AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.firstPeer = peerField.text;
    appDelegate.inst = [NSString stringWithFormat:@"%i", instChoice.selectedSegmentIndex];
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [self setInstChoice:nil];
    [self setPeerField:nil];
    [self setMyIPLabel:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc {
    [myIPLabel release];
    [peerField release];
    [instChoice release];
    [super dealloc];
}


@end
