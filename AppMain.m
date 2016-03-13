//
//  AppMain.m
//  Application8
//
//  Created by Iain Buchanan on 05/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppMain.h"
#import "FlipsideViewController.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#define PEERNAME @"/PEER"
#define REPLY @"/REPL"
#define INSERTPEER @"/JOIN"
#define LISTPEERS @"/LIST"
#define ERROR @"/ERRO"
#define LISTREPLY @"/RLIS"
#define QUERY @"/QUER"
#define QRESPONSE @"/RESP"
#define PING @"PING"
#define EXIT @"/EXIT"

//need to decide what to do with these
#define MESSAGE1 @"/MSG1"
#define MESSAGE2 @"/MSG2"

@interface AppMain()

- (void) startAudio;

@end

@implementation AppMain

@synthesize flipside;

- (id) init {
    
    updateTime = [NSNumber numberWithInt:1000];
    loopList = [[MutLockDict alloc] initWithCapacity:4];
    
	loop = @"0";
    peerCount = 0; //used for allowing observer without disturbing loopList
    
	manager = [[OSCManager alloc] init];
	[manager setDelegate:self];
	
	[manager createNewInputForPort:9001];
    
    #if TARGET_IPHONE_SIMULATOR
	int ticksPerBuffer = 512 / [PdBase getBlockSize];
    #else
	int ticksPerBuffer = 64; //might just work with 64 anyway...
    #endif
    //NSLog(@"tpb: %i", ticksPerBuffer);
    
    pdAudio = [[PdAudio alloc] initWithSampleRate:44100.0 andTicksPerBuffer:ticksPerBuffer andNumberOfInputChannels:2 andNumberOfOutputChannels:2 
                          andAudioSessionCategory:kAudioSessionCategory_AmbientSound];
    
	return self;
}

- (void)quitSession {
    [pdAudio pause];
    [PdBase closeFile:@"basics1.pd"];
    [pdAudio dealloc]; //dealloc?
    NSEnumerator *loopEnum = [btPeer.peers objectEnumerator];
    NSString *exitPeer;
    while ((exitPeer = [loopEnum nextObject]) != NULL) {
        [btPeer sendEXIT:exitPeer andInst:inst];
    }
    /*[btPeer release];
    [super dealloc]; //probably unnecessary */
}

- (void) startNetwork:(NSString *)theHost andInst:(NSString *)theInst {
    
    btPeer = [[btpeer alloc] initWithArgs:4 andPort:9001 andManager:manager]; 
    [btPeer buildPeers:theHost andPort:9001 andDepth:4]; //so this one takes the "first peer to try" argsO];
    
    if ([theInst isEqualToString:@"5"]) {
        //no instrument for the observer peer
        inst = theInst;
    }
    else {
        inst = [NSString stringWithFormat:@"%i", [self getInstrument:theInst]];
        [loopList setValue:loop forKey:inst];
        NSEnumerator *loopEnum = [btPeer.peers objectEnumerator];
        NSString *peer;
        while ((peer = [loopEnum nextObject]) != NULL) {
            [btPeer handleQUERY:peer andInst:inst andLoop:loop];
        }
    }
    
    NSLog(@"inst: %@", inst);
    
    //so we need to inform peers of our chosen inst/loop
    
    [btPeer startStabilizer:@"checkLivePeers" interval:3];
    
    //[self performSelector:NSSelectorFromString(@"onTimer") withObject:nil afterDelay:2]; //replace me with timer constant
    //ontimer not required as it just updates list view
}

+ (NSString*) initServerHost {
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

- (void)receivedOSCMessage:(OSCMessage *)m {
	NSLog(@"Received a message: %@", [m address]);
	
	if ([[m address] isEqualToString:PEERNAME]) {
		[btPeer handlePEERNAME:[[m value] stringValue]];
		return;
	}
    
    else if ([[m address] isEqualToString:LISTPEERS]) {
        //how to handle listing peers
        [btPeer handleLISTPEERS:[[m value] stringValue]];
    }
	
	else if ([[m address] isEqualToString:LISTREPLY]) {
		//NSMutableArray *temp = [[NSMutableArray alloc] ;
		if ([[[m value] stringValue] isEqualToString:@"NONE"]) {
			NSLog(@"empty list reply response");
			tempListReplyArray = nil;
		}
		else {
            NSLog(@"list reply response contains stuff!");
			tempListReplyArray = [[[m value] stringValue] componentsSeparatedByString:@","];
		}
		[btPeer setTempPeerArray:tempListReplyArray];
	}
	
	else if ([[m address] isEqualToString:REPLY]) {
		NSLog(@"REPLY: %@", [m value]);
		if ([[[m value] stringValue] isEqualToString:@"PEERADDED"]) {
			[btPeer setTempPeerId:@"1"];
		}
		else if ([[[m value] stringValue] isEqualToString:@"JOINERROR"]) {
			[btPeer setTempPeerId:@"ERROR"];
		}
		else {
			[btPeer setTempPeerId:[[m value] stringValue]];
		}
	}
	
	else if ([[m address] isEqualToString:INSERTPEER]) {
		[btPeer handleINSERTPEER:[[m value] stringValue]];
	}
	
	else if ([[m address] isEqualToString:QUERY]) {
		[btPeer handleQUERY:[[m value] stringValue] andInst:inst andLoop:loop];
	}
	
	else if ([[m address] isEqualToString:QRESPONSE]) {
		NSArray *data = [[[m value] stringValue] componentsSeparatedByString:@","];
        if ([[data objectAtIndex:0] isEqualToString:@"5"]) {
            //if observer, skip it
            peerCount--;
        }
        else {
            [loopList setValue:[data objectAtIndex:1] forKey:[data objectAtIndex:0]];
            [self update:[data objectAtIndex:0] andLoop:[data objectAtIndex:1]];
        }
	}
    
    else if ([[m address] isEqualToString:EXIT]) {
        //needs to take id,inst
        NSArray *exitData = [[[m value] stringValue] componentsSeparatedByString:@","];
        [loopList setValue:@"0" forKey:[exitData objectAtIndex:1]];
        [self update:[exitData objectAtIndex:1] andLoop:@"0"];
        [btPeer handleEXIT:[exitData objectAtIndex:0]];
    }
    
    else if ([[m address] isEqualToString:PING]) {
        btPeer.checkPeer = @"ping";
    }
    
    else if ([[m address] isEqualToString:MESSAGE1]) {
        NSLog(@"received message1");
        //need to push this to interface
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session Update" //appmain inst
                                                        message:[[m value] stringValue]
                                                       delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    else if ([[m address] isEqualToString:MESSAGE2]) {
        //need to push this to interface
    }
	
	else {
		NSLog(@"Unrecognised message.");
	}
}

- (int)getInstrument:(NSString *)instChoice {
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:4];
    BOOL loopResponse = [self updateLoopList];
    int retValue = 0;
    //iterate through loopList to make temp array
    //fill empty slots with 0s
    for (int i = 1; i != 5; ++i) { //place for looplist length
        if ([loopList objectForKey:[NSString stringWithFormat:@"%i", i]] == nil) {
            [tempArray addObject:[NSNumber numberWithInt:i]];
            [loopList setValue:@"0" forKey:[NSString stringWithFormat:@"%i", i]];
        }
    }
	if (loopResponse == NO) {
        if ([instChoice isEqualToString:@"0"]) { //if "any" chosen return a random
            retValue = 1 + arc4random() % 4;
        }
		else { //otherwise return their choice
            return [instChoice intValue];
        }
	}
	else {
        if (![instChoice isEqualToString:@"0"]) {
            for (int j = 0; j != [tempArray count]; ++j) {
                if ([tempArray objectAtIndex:j] == [NSNumber numberWithInteger:[instChoice intValue]]) {
                    [tempArray removeObjectAtIndex:j];
                }
            }
        }
        retValue = [[tempArray objectAtIndex:arc4random() % ([tempArray count] - 1)] intValue];
	}
    [tempArray release]; //risky business
    return retValue;
}

- (BOOL)updateLoopList {    

    if ([btPeer.peers count] == 0) {
        return NO;
    }
    else {
        NSEnumerator *peerEnum = [btPeer.peers objectEnumerator];
        NSString *peer;
        //int count = 0;
        peerCount = 0;
        while ((peer = [peerEnum nextObject]) != NULL) {
            [btPeer sendQUERY:myId to:peer];
            peerCount++;
        }
        //wait for peer responses
        while ([loopList count] != peerCount) {
            //wait AND ADD TIMEOUT
        }
        return YES;
    }
}



/********************************************
 AUDIO METHODS AND JAZZ
 ********************************************/

- (void)startAudio {
    [PdBase setDelegate:flipside];
	[PdBase openFile:@"basics1.pd" path:[[NSBundle mainBundle] bundlePath]];
	[PdBase computeAudio:YES];
	[pdAudio play];
    [PdBase sendBangToReceiver:@"start"];
    NSLog(@"audio started...");
}

- (void)buttonPress:(NSString *)button {
    loop = button;
    [loopList setValue:loop forKey:inst];
    NSString *target = [NSString stringWithFormat:@"ch%@", inst];
    NSLog(@"inst: %@ loop: %@", target, button);
    [PdBase sendFloat:[loop floatValue] toReceiver:target];
    NSEnumerator *loopEnum = [btPeer.peers objectEnumerator];
    NSString *peer;
    while ((peer = [loopEnum nextObject]) != NULL) {
        [btPeer handleQUERY:peer andInst:inst andLoop:loop];
    }
}

- (void)update:(NSString *)targetInst andLoop:(NSString *)newLoop {
    NSLog(@"audio update from peer: %@/%@", targetInst, newLoop);
    [PdBase sendFloat:[newLoop floatValue] toReceiver:[NSString stringWithFormat:@"ch%@", targetInst]];
}

- (void)setVolume:(float)volume {
    [PdBase sendFloat:volume toReceiver:@"volume"];
}

/********************
 DEBUG STUFF
 ********************/

- (NSString *)getPeerList {
    return [NSString stringWithFormat:@"%@", btPeer.peers];
}

- (NSString *)getLoopList {
    return [NSString stringWithFormat:@"%@", loopList];
}

- (NSString *)getInst {
    if ([inst isEqualToString:@"1"]) {
        return @"Percussion";
    }
    else if ([inst isEqualToString:@"2"]) {
        return @"Bass";
    }
    else if ([inst isEqualToString:@"3"]) {
        return @"Drums";
    }
    else if ([inst isEqualToString:@"5"]) {
        return @"Observer";
    }
    else {
        return @"Keyboard";
    }
}

@end
