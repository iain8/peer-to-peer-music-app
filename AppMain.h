//
//  AppMain.h
//  Application8
//
//  Created by Iain Buchanan on 05/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VVOSC.h"
#import "btpeer.h"
#import "PdAudio.h"
#import "VVBasics.h"

@class AppMain;

@interface AppMain : NSObject <PdReceiverDelegate> {
    //UIWindow *window;
	int maxPeers;
	NSNumber *updateTime;
    MutLockDict *loopList; //replaces both of the above
	NSString *inst;
	NSString *loop;
	btpeer *btPeer;
	NSMutableArray *peers;
	OSCManager *manager;
	NSLock *peerLock;
	NSString *myId;
	NSString *tempPeerId;
    id flipside;
    PdAudio *pdAudio;
    NSArray *tempListReplyArray;
    int peerCount;
}

- (void) startNetwork:(NSString *)theHost andInst:(NSString *)theInst;
+ (NSString*) initServerHost;
- (int) getInstrument:(NSString *)instChoice;
- (BOOL) updateLoopList;
- (void) startAudio;
- (void) buttonPress:(NSString *)button;
- (void) setVolume:(float)volume;
- (void) update:(NSString *)targetInst andLoop:(NSString *)newLoop;
- (NSString*) getPeerList;
- (NSString*) getLoopList;
- (NSString*) getInst;
- (void) quitSession;

@property (retain) id flipside;

@end
