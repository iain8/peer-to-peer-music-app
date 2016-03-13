//
//  btpeer.h
//  network2
//
//  Created by Iain Buchanan on 15/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "btpeer.h"
#import "VVOSC/VVOSC.h"
#import "VVThreadLoop.h"
#import "MutLockArray.h"

//@class AsyncSocket;

@interface btpeer : NSObject {
	int maxPeers;
	NSString *serverHost;
	NSString *myId;
	int serverPort;
	//NSMutableArray *peers;
    MutLockArray *peers;
	NSArray *handlers;
	NSArray *router; //may need to change, structs look good (even use same syntax {} )
	bool shutdown;
	NSLock *peerLock;
	NSRunLoop *runLoop;
	OSCManager *manager;
	OSCOutPort *outPort;
	OSCMessage *msg;
	NSString *tempPeerId;
	NSMutableArray *tempPeerArray;
    NSString *checkPeer;
    VVThreadLoop *threadLoop;
    NSMutableString *peerListReturn;
}

- (id) initWithArgs: (int)peer andPort: (int)port andManager: (OSCManager *)man;
- (NSString*) initServerHost;
- (bool) maxPeersReached;
- (void) buildPeers:(NSString *)host andPort:(int)port andDepth:(int)hops;
- (void)startStabilizer:(NSString *)function interval:(int)time;

- (void)handlePEERNAME:(NSString *)peerId;
- (void)handleINSERTPEER:(NSString *)peerId;
- (void)sendQUERY:(NSString *)peerId to:(NSString *)outId;
- (void)handleQUERY:(NSString *)peerId andInst:(NSString *)inst andLoop:(NSString *)loop;
- (void)handleLISTPEERS:(NSString *)peerId;
- (void)sendEXIT:(NSString *)peerId andInst:(NSString *)inst;
- (void)handleEXIT:(NSString *)peerId;

- (bool)addPeer:(NSString *)peerId;
- (void)removePeer:(NSString *)peerId;
- (void)checkLivePeers;
- (void) setTempPeerId:(NSString *)pid;
- (void) setTempPeerArray:(NSArray *)array;
- (bool) peerArrayContains:(NSString *)str;
- (NSString *) peerListString;

//@property (readonly) NSMutableArray *peers;
@property (readonly) MutLockArray *peers;
@property (retain) NSString *checkPeer;
@property (retain) NSString *myId;

@end
