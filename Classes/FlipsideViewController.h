//
//  FlipsideViewController.h
//  Application9
//
//  Created by Iain Buchanan on 08/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBShapedButton.h"
#import "AppMain.h"
#import "PdAudio.h"

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController <PdReceiverDelegate> {
	id <FlipsideViewControllerDelegate> delegate;
    OBShapedButton *button1;
    OBShapedButton *button2;
    OBShapedButton *button3;
    OBShapedButton *button4;
    //UILabel *beatMeter;
    AppMain *appMain;
    NSString *activeButton;
    PdAudio *pdAudio;
    int currentBeat;
    UIPageControl *beatMeter;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet OBShapedButton *button1;
@property (nonatomic, retain) IBOutlet OBShapedButton *button2;
@property (nonatomic, retain) IBOutlet OBShapedButton *button3;
@property (nonatomic, retain) IBOutlet OBShapedButton *button4;
//@property (nonatomic, retain) IBOutlet UILabel *beatMeter;
@property (nonatomic, retain) IBOutlet UIPageControl *beatMeter;

- (IBAction)done:(id)sender;
- (IBAction)button1Press:(id)sender;
- (IBAction)volSliderChange:(UISlider *)sender;
- (IBAction)showInfo;
- (void)pulseButton;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

