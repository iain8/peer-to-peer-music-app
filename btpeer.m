//
//  btpeer.m
//  network2
//
//  Created by Iain Buchanan on 15/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  ip address code in initServerHost from http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone

#import "btpeer.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include "TargetConditionals.h"
#import "VVStopwatch.h"

#define PEERNAME @"/PEER"
#define REPLY @"/REPL"
#define INSERTPEER @"/JOIN"
#define LISTPEERS @"/LIST"
#define ERROR @"/ERRO"
#define LISTREPLY @"/RLIS"
#define QUERY @"/QUER"
#define QRESPONSE @"/RESP"
#define PING @"/PING"
#define EXIT @"/EXIT"

@implementation btpeer

@synthesize peers;
@synthesize checkPeer;
@synthesize myId;

- (id) init {
	return self;
}

- (id) initWithArgs: (int)peer andPort: (int)port andManager: (OSCManager *)man {
	self = [super init];
	maxPeers = 5;
	//peers = [[NSMutableArray alloc] init];
    peers = [[MutLockArray alloc] initWithCapacity:maxPeers];
	peerLock = [[NSLock alloc] init];
	maxPeers = peer;
	serverPort = port;
	serverHost = [self initServerHost];
	self.myId = [NSString stringWithFormat:@"%@:%d", serverHost, serverPort];
	manager = man;
	tempPeerId = nil;
	tempPeerArray = nil;
    checkPeer = nil;
    threadLoop = [threadLoop initWithTimeInterval:2.0 target:self selector:NSSelectorFromString(@"checkLivePeers")];
    peerListReturn = [[NSMutableString alloc] initWithString:@""];
	return self;
}

- (NSString*) initServerHost {
	//get local ip address
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	NSString *interfaceName;
	
	// retrieve the current interfaces - returns 0 on success (why god why?!)
	success = getifaddrs(&interfaces);	
	
	if (success == 0) {
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL) {
			if(temp_addr->ifa_addr->sa_family == AF_INET) {
				#if (TARGET_IPHONE_SIMULATOR)
				interfaceName = @"en1";
				#else
				interfaceName = @"en0";
				#endif
				// Check if interface is en0 (en1 in sim) which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:interfaceName]) {
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	NSLog(@"Local address: %@", address);
	return address;
}

- (void)buildPeers:(NSString *)host andPort:(int)port andDepth:(int)hops {
	if ([self maxPeersReached] || hops == 0) {
		return;
	}
	NSString *peerId = nil;
	@try {
		outPort = [manager createNewOutputToAddress:host atPort:port];
		
		msg = [OSCMessage createWithAddress:PEERNAME];
		[msg addString:myId];
		[outPort sendThisMessage:msg];
		//wait for return of peerid
        VVStopwatch *timer = [VVStopwatch create];
		while (tempPeerId == nil && [timer timeSinceStart] < 2.0) {
			//wait 2 seconds for reply... can override if needs be
		}
        if (tempPeerId == nil) {
            return;
        }
        NSLog(@"buildPeers - contacted peer: %@", tempPeerId);
		peerId = [NSString stringWithFormat:@"%@", tempPeerId];
		tempPeerId = nil;

		msg = [OSCMessage createWithAddress:INSERTPEER];
		[msg addString:myId];
		[outPort sendThisMessage:msg];
        [timer start];
		while (tempPeerId == nil && [timer timeSinceStart] < 10.0) {
			//10 second timeout if we've actually contacted peer
            //but if this times out is it better to actually cancel starting main app?
		}
		if (tempPeerId == @"ERROR" || [self peerArrayContains:peerId] || tempPeerId == nil) { //in the case of errors tempPeerId = 0
			return;
		}
		[self addPeer:peerId];

		//recursive search for more peers (not all that recursive given max 4)
		NSArray *pid = [peerId componentsSeparatedByString:@":"];
		outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
		msg = [OSCMessage createWithAddress:LISTPEERS];
        [msg addString:myId];
		[outPort sendThisMessage:msg];
        NSLog(@"listpeers sent");
		while (tempPeerArray == nil) {
			//another wait
		}
		NSLog(@"response after listpeers");
		if ([tempPeerArray count] > 1) {
			while ([tempPeerArray count] != 0) {
				NSString *nextPid = [tempPeerArray lastObject];
				[tempPeerArray removeLastObject];
				NSArray *pid = [nextPid componentsSeparatedByString:@":"];
				[self buildPeers:[pid objectAtIndex:0] andPort:[[pid objectAtIndex:1] intValue] andDepth:hops - 1];
			}
		}
	}
	@catch (NSException * e) {
		NSLog(@"buildPeers - Exception: %@", e);
		[self removePeer:peerId];
	}
	@finally {
        //[peerId release];
		return;
	}
}

- (void)startStabilizer:(NSString *)function interval:(int)time {
    //if this doesn't work just hardcode method to start particular thread+method
    //try VVThreadLoop first
	//[NSThread detachNewThreadSelector:NSSelectorFromString(function) toTarget:self withObject:[NSNumber numberWithInt:3]];
    //[threadLoop start];
}

- (void)runStabilizer {
	while (!shutdown) {
		//call checklivepeers
        [self checkLivePeers];
		//wait for x seconds (determine w/global var)
        sleep(2);
	}
}

- (bool)maxPeersReached {
	return (maxPeers > 0 && [peers count] == maxPeers);
}

- (bool)addPeer:(NSString *)peerId {
	if (![self peerArrayContains:peerId] && (maxPeers == 0 || [peers count] < maxPeers) 
        && ![peerId isEqualToString:myId] && ([peerId length] > 12)) {
		[peers lockAddObject:[NSString stringWithString:peerId]]; //hopefully adds a copy
        NSLog(@"Added peer %@", peerId);
        NSLog(@"Peers: %@", peers);
		return true;
	}
	else {
		return false;
	}
	
}

- (void)removePeer:(NSString *)peerId {
    NSEnumerator *peerEnum = [peers objectEnumerator];
    NSString *peer;
	while ((peer = [peerEnum nextObject]) != NULL) {
		if ([peer isEqualToString:peerId]) {
			[peers lockRemoveObject:peer];  //does this work?
		}
	}
    //[peerEnum release];
    //[peer release];
}

- (void) checkLivePeers {
    NSLog(@"Checking live peers.");
    NSMutableSet *toDelete;
    NSEnumerator *peerEnum = [peers objectEnumerator];
    NSString *peer;
    while ((peer = [peerEnum nextObject]) != NULL) {
        @try {
            NSArray *pid = [peer componentsSeparatedByString:@":"];
            //send ping to peer, if no reply add them to the list
            outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
            msg = [OSCMessage createWithAddress:PING];
            [outPort sendThisMessage:msg];
            VVStopwatch *timer = [VVStopwatch create];
            while (checkPeer == nil && ([timer timeSinceStart] < 1)) { //1 second timeouts... too little? Stay tuned!
                //do nothing
            }
        }
        @catch (NSException *exception) {
            [toDelete addObject:checkPeer];
            checkPeer = nil;
        }
    }
    @try {
        for (id p in toDelete) {
            if ([self peerArrayContains:p]) {
                [self removePeer:p];
            }
        }
    }
    @catch (NSException *exception) {
        //no catchy exceptiony
    }
    @finally {
        //[toDelete release];
        //[peerEnum release];
        //[peer release];
    }
}

- (bool) peerArrayContains:(NSString *)str {
    NSEnumerator *peerEnum = [peers objectEnumerator];
    NSString *peer;
	while ((peer = [peerEnum nextObject]) != NULL) {
		if ([peer isEqualToString:str]) {
            [peerEnum release];
            [peer release];
			return true;
		}
	}
    //[peerEnum release];
    //[peer release];
	return false;
}

- (void) setTempPeerId:(NSString *)pid {
	tempPeerId = pid;
}

- (void) setTempPeerArray:(NSArray *)array {
	tempPeerArray = [NSArray arrayWithArray:array]; //array;
    NSLog(@"Updated peer array");
}

- (NSString *) peerListString {
    NSEnumerator *peerEnum = [peers objectEnumerator];
    NSString *peer;
    peerListReturn = [NSMutableString stringWithString:@""];
    int count = 0;
    while ((peer = [peerEnum nextObject]) != NULL) {
        if (count != 0) {
            [peerListReturn appendString:@","];
        }
        count++;
        [peerListReturn appendString:peer];
    }
    NSLog(@"peer list is: %@", peerListReturn);
    if ([peerListReturn length] == 0) {
        peerListReturn = [NSMutableString stringWithString:@"NONE"];
    }
    //[peerEnum release];
    //[peer release];
    return peerListReturn;
}


/********MESSAGE HANDLERS*********/
- (void)handlePEERNAME:(NSString *)peerId {
    NSLog(@"myId: %@", self.myId);
	//split string
	NSArray *pid = [peerId componentsSeparatedByString:@":"];
	outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
    //[pid release];
	msg = [OSCMessage createWithAddress:REPLY];
	[msg addString:[NSString stringWithFormat:@"%@", myId]];
	[outPort sendThisMessage:msg];
}

- (void)handleINSERTPEER:(NSString *)peerId {
	NSArray *pid = [peerId componentsSeparatedByString:@":"];
	@try {
		@try {
			if ([self maxPeersReached]) {
				NSLog(@"Maximum peers reached.");
				outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
				msg = [OSCMessage createWithAddress:ERROR];
				[msg addString:@"JOINERROR"];
				[outPort sendThisMessage:msg];
				return;
			}
			if (![peers containsObject:peerId] && peerId != myId) {
				[self addPeer:peerId];
				outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
				msg = [OSCMessage createWithAddress:REPLY];
				[msg addString:[NSString stringWithFormat:@"PEERADDED"]];
				[outPort sendThisMessage:msg];
				return;
			}
			else {
				outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
				msg = [OSCMessage createWithAddress:ERROR];
				[msg addString:[NSString stringWithFormat:@"JOINERROR", peerId]];
				[outPort sendThisMessage:msg];
				return;
			}
		}
		@catch (NSException * e) {
			NSLog(@"Invalid insert %@", peerId);
			outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
			msg = [OSCMessage createWithAddress:ERROR];
			[msg addString:@"JOINERROR"];
			[outPort sendThisMessage:msg];
		}
	}
	@finally {
		//do nowt
	}
}

- (void)handleLISTPEERS:(NSString *)peerId {
	NSArray *pid = [peerId componentsSeparatedByString:@":"];
	@try {
		NSLog(@"Listing %d peer(s)", [peers count]);
		NSString *list = [self peerListString]; //[peers componentsJoinedByString:@","];
		outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
		msg = [OSCMessage createWithAddress:LISTREPLY];
		[msg addString:list];
		[outPort sendThisMessage:msg];
        NSLog(@"listreply sent to %@", pid);
	}
	@catch (NSException * e) {
		NSLog(@"List error %@", e);
		outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
		msg = [OSCMessage createWithAddress:ERROR];
		[msg addString:@"LISTERROR"];
		[outPort sendThisMessage:msg];
	}
	@finally {
        //do nothing
	}
}

- (void)handleQUERY:(NSString *)peerId andInst:(NSString *)inst andLoop:(NSString *)loop {
	NSLog(@"Responding to query");
	NSArray *pid = [peerId componentsSeparatedByString:@":"];
	NSString *data = [inst stringByAppendingFormat:@",%@", loop];
	outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
	msg = [OSCMessage createWithAddress:QRESPONSE];
	[msg addString:data];
	[outPort sendThisMessage:msg];
}

- (void)sendQUERY:(NSString *)peerId to:(NSString *)outId {
	NSArray *pid = [outId componentsSeparatedByString:@":"];
	outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
	msg = [OSCMessage createWithAddress:QUERY];
	[msg addString:myId];
	[outPort sendThisMessage:msg];
}

- (void)sendEXIT:(NSString *)peerId andInst:(NSString *)inst {
    NSArray *pid = [peerId componentsSeparatedByString:@":"];
    NSString *data = [myId stringByAppendingFormat:@",", inst];
	outPort = [manager createNewOutputToAddress:[pid objectAtIndex:0] atPort:[[pid objectAtIndex:1] intValue]];
	msg = [OSCMessage createWithAddress:EXIT];
	[msg addString:data];
	[outPort sendThisMessage:msg];
    [manager deleteAllInputs];
    [manager deleteAllOutputs];
    [manager dealloc];
}

- (void)handleEXIT:(NSString *)peerId {
    [self removePeer:peerId];
}
/********END MESSAGE HANDLERS*********/

@end
