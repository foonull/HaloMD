//
//  MDChatWindowController.h
//  HaloMD
//
//  Created by null on 2/23/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Ruby/ruby.h>

#define CHAT_PLAY_MESSAGE_SOUNDS @"CHAT_PLAY_MESSAGE_SOUNDS"
#define CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION @"CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION"

@class WebView;

@interface MDChatWindowController : NSWindowController
{
	IBOutlet WebView *webView;
	IBOutlet NSTextView *textView;
	IBOutlet NSSplitView *chatSplitView;
	IBOutlet NSSplitView *rosterSplitView;
	IBOutlet NSTableView *rosterTableView;
	VALUE chatting;
	VALUE chattingClass;
	NSTimer *chatTimer;
	int previousMaxScroll;
	uint64_t numberOfUnreadMentions;
	NSMutableArray *roster;
	NSString *myNick;
	BOOL willTerminate;
}

@property (nonatomic, copy) NSString *myNick;

- (void)cleanup;

@end
