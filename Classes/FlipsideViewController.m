//
//  FlipsideViewController.m
//  Application9
//
//  Created by Iain Buchanan on 08/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "MainViewController.h"
#import "Application9AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "VVThreadLoop.h"


@implementation FlipsideViewController

@synthesize delegate;
@synthesize button1;
@synthesize button2;
@synthesize button3;
@synthesize button4;
@synthesize beatMeter;


- (void)viewDidLoad {
    [super viewDidLoad];

    Application9AppDelegate *appDelegate = (Application9AppDelegate *)[[UIApplication sharedApplication] delegate];
    appMain = [[AppMain alloc] init];
    appMain.flipside = self;
    [appMain startNetwork:appDelegate.firstPeer andInst:appDelegate.inst];
    [appMain startAudio];
    
    [PdBase setDelegate:self];
    [PdBase subscribe:@"receive"];
    [PdBase subscribe:@"cue"];
    
    activeButton = 0;
    currentBeat = 0;
    
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];      
}


- (IBAction)done:(id)sender {
    //this is where we stop everything
    [appMain quitSession];
    NSLog(@"Fin.");
	[self.delegate flipsideViewControllerDidFinish:self];	
}

//all main button presses
- (IBAction)button1Press:(id)sender {
    UIButton *pressed = (UIButton *)sender;
    if ([activeButton isEqualToString:pressed.currentTitle]) {
        [appMain buttonPress:@"0"];
        activeButton = @"0";
    }
    else {
        [appMain buttonPress:pressed.currentTitle];
        activeButton = pressed.currentTitle;
    }
}

- (IBAction)volSliderChange:(UISlider *)sender {
    NSLog(@"Volume change: %f", [sender value]);
    [appMain setVolume:[sender value]];
}

- (IBAction)showInfo {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session info" //appmain inst
                                                    message:[NSString stringWithFormat:@"Instrument: %@\n%@, %@",
                                                             [appMain getInst], [appMain getPeerList], [appMain getLoopList]]
                                                   delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)pulseButton {
    if ([activeButton isEqualToString:@"0"]) {
        return;
    }
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.4; //tweak to timing
    anim.repeatCount = 1;
    anim.autoreverses = YES;
    anim.removedOnCompletion = YES;
    anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
    if ([activeButton isEqualToString:@"1"]) {
        [button1.layer addAnimation:anim forKey:nil];
    }
    else if ([activeButton isEqualToString:@"2"]) {
        [button2.layer addAnimation:anim forKey:nil];
    }
    if ([activeButton isEqualToString:@"3"]) {
        [button3.layer addAnimation:anim forKey:nil];
    }
    if ([activeButton isEqualToString:@"4"]) {
        [button4.layer addAnimation:anim forKey:nil];
    }
    //NSLog(@"BAAA");
}

- (void)receivePrint:(NSString *)message {
    [self performSelectorOnMainThread:@selector(pulseButton)withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(updateBeatMeter)withObject:nil waitUntilDone:NO];
    if (currentBeat == 3) {
        currentBeat = 0;
    }
    else {
        currentBeat++;
    }
}

- (void)receiveFloat:(float)value fromSource:(NSString *)source {
    NSLog(@"This just in: %@ - %f", source, value);
}

- (void)updateBeatMeter {
    beatMeter.currentPage = currentBeat;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [self setBeatMeter:nil];
    [self setBeatMeter:nil];
    [self setButton4:nil];
    [self setButton3:nil];
    [self setButton2:nil];
    [self setButton1:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc {
    [button1 release];
    [button2 release];
    [button3 release];
    [button4 release];
    //[beatMeter release];
    [beatMeter release];
    [super dealloc];
}


@end
