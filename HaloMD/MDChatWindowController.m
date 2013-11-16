/*
 * Copyright (c) 2013, Null <foo.null@yahoo.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this
 * list of conditions and the following disclaimer in the documentation and/or
 * other materials provided with the distribution.
 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  MDChatWindowController.m
//  HaloMD
//
//  Created by null on 2/23/13.
//

#import "MDChatWindowController.h"
#import "MDChatRosterElement.h"
#import <WebKit/WebKit.h>
#import <Growl/Growl.h>
#import <CommonCrypto/CommonDigest.h>
#import "AppDelegate.h"
#import "MDServer.h"

@implementation MDChatWindowController

@synthesize myNick;

static MDChatWindowController *gChatController = nil;

static VALUE processMessage(VALUE self, VALUE type, VALUE message, VALUE nick, VALUE text);

#define MD_STATUS_PREFIX @"!MD"

- (id)init
{
	self = [super initWithWindowNibName:NSStringFromClass([self class])];
	if (self)
	{
		gChatController = self;
		chatting = Qnil;
		
		previousMaxScroll = -1;
		
		NSString *chatScriptPath = [[NSBundle mainBundle] pathForResource:@"chatting" ofType:@"rb"];
		
		chattingClass = rb_define_class("Chatting", rb_cObject);
		rb_define_method(chattingClass, "process", processMessage, 4);
		rb_define_method(chattingClass, "clear", clearAllMessages, 0);
		rb_define_method(chattingClass, "presence_changed", presenceChanged, 1);
		
		int requireState = 0;
		rb_protect(requireWrapper, rb_str_new2([chatScriptPath UTF8String]), &requireState);
		if (requireState != 0)
		{
			NSLog(@"Failed to initiate Chat window Controller. Ruby Require Failed");
			[self release];
			return nil;
		}
		
		roster = [[NSMutableArray alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];
		
		[[NSApp delegate] addObserver:self forKeyPath:@"inGameServer" options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"inGameServer"])
	{
		updateMyStatus();
	}
}

- (void)setNumberOfUnreadMentions:(uint64_t)newNumberOfUnreadMentions
{
	numberOfUnreadMentions = newNumberOfUnreadMentions;
	if (numberOfUnreadMentions == 0)
	{
		[[NSApp dockTile] setBadgeLabel:@""];
	}
	else
	{
		[[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%llu", numberOfUnreadMentions]];
	}
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
	[self setNumberOfUnreadMentions:0];
}

static BOOL signedOnForFirstTime = NO;

static VALUE signOnSafely(VALUE self)
{
	if (gChatController->chatting == Qnil)
	{
		rb_define_variable("$chatting", &(gChatController->chatting));
		gChatController->chatting = rb_funcall(gChatController->chattingClass, rb_intern("new"), 0);
	}
	
	NSMutableString *strippedNickname = [NSMutableString string];
	NSString *profileName = [[NSApp delegate] profileName];
	for (NSUInteger profileNameIndex = 0; profileNameIndex < [profileName length]; profileNameIndex++)
	{
		unichar character = [profileName characterAtIndex:profileNameIndex];
		if (isascii(character))
		{
			[strippedNickname appendString:[NSString stringWithCharacters:&character length:1]];
		}
	}
	
	NSMutableString *nickname = [NSMutableString stringWithString:strippedNickname];
	if (!nickname || [nickname length] == 0)
	{
		nickname = [NSMutableString stringWithString:@"HaloNewb"];
	}
	
	[nickname replaceOccurrencesOfString:@" " withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [nickname length])];
	
	NSString *serialKey = [[NSApp delegate] machineSerialKey];
	if (!serialKey)
	{
		serialKey = [[NSApp delegate] serialKey];
	}
	if (!serialKey)
	{
		serialKey = [[NSApp delegate] randomSerialKey];
	}
	
	gChatController->chatTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05
												  target:gChatController
												selector:@selector(updateChat:)
												userInfo:nil
												 repeats:YES] retain];
	
	rb_funcall(gChatController->chatting, rb_intern("connect_and_auth"), 2, rb_str_new2([serialKey UTF8String]), rb_str_new2([nickname UTF8String]));
	
	signedOnForFirstTime = YES;
	
	return Qnil;
}

- (void)signOn
{
	int exceptionState = 0;
	rb_protect(signOnSafely, Qnil, &exceptionState);
	if (exceptionState != 0)
	{
		NSLog(@"Error: Failed to sign on properly");
	}
}

- (void)cleanup
{
	willTerminate = YES;
}

static VALUE exitRoomSafely(VALUE data)
{
	rb_funcall(gChatController->chatting, rb_intern("exit"), 0);
	return Qnil;
}

- (void)signOff
{
	if (!willTerminate)
	{
		if (chatting != Qnil)
		{
			int exceptionState = 0;
			rb_protect(exitRoomSafely, Qnil, &exceptionState);
			if (exceptionState != 0)
			{
				NSLog(@"Error: Failed to exit chatroom");
			}
		}
		if (chatTimer)
		{
			[chatTimer invalidate];
			[chatTimer release];
			chatTimer = nil;
		}
	}
}

- (NSString *)currentStatus
{
	MDServer *inGameServer = [[NSApp delegate] inGameServer];
	
	if ([[NSApp delegate] isHaloOpen])
	{
		if (!inGameServer)
		{
			return MD_STATUS_PREFIX;
		}
		
		return [[NSArray arrayWithObjects:MD_STATUS_PREFIX, [inGameServer ipAddress], [NSString stringWithFormat:@"%d", [inGameServer portNumber]], nil] componentsJoinedByString:@":"];
	}
	
	return nil;
}

static void updateMyStatus(void)
{
	if (gChatController->chatTimer && gChatController->chatting != Qnil)
	{
		NSString *currentStatus = [gChatController currentStatus];
		rb_funcall(gChatController->chatting, rb_intern("set_status"), 1, currentStatus == nil ? Qnil : rb_str_new2([currentStatus UTF8String]));
	}
}

- (void)addNickToRoster:(NSString *)nicknameToAdd
{
	struct RArray *rosterElements = (struct RArray *)rb_funcall(gChatController->chatting, rb_intern("roster"), 0);
	if ((VALUE)rosterElements != Qnil && TYPE(rosterElements) == T_ARRAY)
	{
		for (long rosterElementIndex = 0; rosterElementIndex < rosterElements->len; rosterElementIndex++)
		{
			struct RArray *userItems = (struct RArray *)rosterElements->ptr[rosterElementIndex];
			if ((VALUE)userItems != Qnil && TYPE(userItems) == T_ARRAY && userItems->len >= 2 && userItems->ptr[0] != Qnil && userItems->ptr[1] != Qnil)
			{
				StringValue(userItems->ptr[0]);
				
				NSString *nickname = [[[NSString alloc] initWithBytes:RSTRING_PTR(userItems->ptr[0]) length:RSTRING_LEN(userItems->ptr[0]) encoding:NSUTF8StringEncoding] autorelease];
				if ([nickname isEqualToString:nicknameToAdd])
				{
					VALUE presence = userItems->ptr[1];
					VALUE statusValue = rb_funcall(presence, rb_intern("status"), 0);
					if (statusValue != Qnil) StringValue(statusValue);
					NSString *status = statusValue == Qnil ? nil : [[[NSString alloc] initWithBytes:RSTRING_PTR(statusValue) length:RSTRING_LEN(statusValue) encoding:NSUTF8StringEncoding] autorelease];
					VALUE fromValue = rb_funcall(presence, rb_intern("from"), 0);
					VALUE jabberIdentifierValue = fromValue == Qnil ? Qnil : rb_funcall(fromValue, rb_intern("to_s"), 0);
					if (jabberIdentifierValue != Qnil) StringValue(jabberIdentifierValue);
					NSString *jabberIdentifier = jabberIdentifierValue == Qnil ? nil : [[[NSString alloc] initWithBytes:RSTRING_PTR(jabberIdentifierValue) length:RSTRING_LEN(jabberIdentifierValue) encoding:NSUTF8StringEncoding] autorelease];
					
					MDChatRosterElement *newRosterElement = [[MDChatRosterElement alloc] init];
					[newRosterElement setName:nickname];
					[newRosterElement setStatus:status];
					[newRosterElement setJabberIdentifier:jabberIdentifier];
					
					[roster addObject:newRosterElement];
					
					[rosterTableView reloadData];
					
					break;
				}
			}
		}
	}
}

static VALUE presenceChanged(VALUE self, VALUE presence)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	VALUE fromValue = rb_funcall(presence, rb_intern("from"), 0);
	VALUE jabberIdentifierValue = fromValue == Qnil ? Qnil : rb_funcall(fromValue, rb_intern("to_s"), 0);
	if (jabberIdentifierValue != Qnil) StringValue(jabberIdentifierValue);
	NSString *jabberIdentifier = jabberIdentifierValue == Qnil ? nil : [[[NSString alloc] initWithBytes:RSTRING_PTR(jabberIdentifierValue) length:RSTRING_LEN(jabberIdentifierValue) encoding:NSUTF8StringEncoding] autorelease];
	
	if (jabberIdentifier)
	{
		for (MDChatRosterElement *rosterElement in gChatController->roster)
		{
			if ([[rosterElement jabberIdentifier] isEqualToString:jabberIdentifier])
			{
				VALUE statusValue = rb_funcall(presence, rb_intern("status"), 0);
				if (statusValue != Qnil) StringValue(statusValue);
				NSString *status = statusValue == Qnil ? nil : [[[NSString alloc] initWithBytes:RSTRING_PTR(statusValue) length:RSTRING_LEN(statusValue) encoding:NSUTF8StringEncoding] autorelease];
				
				[rosterElement setStatus:status];
				
				[gChatController->rosterTableView reloadData];
				
				break;
			}
		}
	}
	
	[autoreleasePool release];
	
	return Qnil;
}

- (NSArray *)tokensFromString:(NSString *)string
{
	NSMutableArray *tokens = [NSMutableArray array];
	NSString *iteratingString = string;
	
	while (YES)
	{
		NSRange httpRange = [iteratingString rangeOfString:@"http://" options:NSLiteralSearch | NSCaseInsensitiveSearch];
		NSRange httpsRange = [iteratingString rangeOfString:@"https://" options:NSLiteralSearch | NSCaseInsensitiveSearch];
		
		NSRange bestRange;
		if (httpRange.location == NSNotFound && httpsRange.location == NSNotFound)
		{
			// Stop here
			[tokens addObject:iteratingString];
			break;
		}
		else if (httpRange.location == NSNotFound && httpsRange.location != NSNotFound)
		{
			bestRange = httpsRange;
		}
		else if (httpRange.location != NSNotFound && httpsRange.location == NSNotFound)
		{
			bestRange = httpRange;
		}
		else if (httpRange.location < httpsRange.location)
		{
			bestRange = httpRange;
		}
		else /* if (httpsRange.location < httpRange) */
		{
			bestRange = httpsRange;
		}
		
		[tokens addObject:[iteratingString substringToIndex:bestRange.location]];
		
		NSString *url = [[[iteratingString substringFromIndex:bestRange.location] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] objectAtIndex:0];
		
		[tokens addObject:url];
		
		iteratingString = [iteratingString substringFromIndex:bestRange.location+[url length]];
	}
	
	return tokens;
}

- (void)processMessageWithArguments:(NSArray *)arguments
{
	NSString *typeString = [arguments objectAtIndex:0];
	NSString *messageString = [arguments objectAtIndex:1];
	NSString *nickString = [arguments objectAtIndex:2];
	if ((id)nickString == [NSNull null]) nickString = nil;
	NSString *textString = [arguments objectAtIndex:3];
	if ((id)textString == [NSNull null]) textString = nil;
	
	DOMDocument *document = [[webView mainFrame] DOMDocument];
	DOMElement *contentBlock = [document getElementById:@"content"];
	
	NSMutableArray *messageDOMComponents = [NSMutableArray array];
	
	if (messageString)
	{
		NSArray *textTokens = [self tokensFromString:messageString];
		for (id textToken in textTokens)
		{
			if ([textToken hasPrefix:@"http://"] || [textToken hasPrefix:@"https://"])
			{
				DOMElement *anchor = [document createElement:@"a"];
				[anchor setAttribute:@"href" value:textToken];
				[anchor setTextContent:textToken];
				[messageDOMComponents addObject:anchor];
			}
			else
			{
				[messageDOMComponents addObject:[document createTextNode:textToken]];
			}
		}
	}
	
	if ([[NSArray arrayWithObjects:@"on_message", @"on_private_message", @"my_message", @"my_private_message", @"on_leave", @"on_self_leave", @"on_join", @"connection_failed", @"connection_failed_timeout", @"muc_join_failed", @"connection_initiating", @"muc_joined", @"roster", @"subject", nil] containsObject:typeString])
	{
		DOMElement *newParagraph = [document createElement:@"p"];
		[newParagraph setAttribute:@"class" value:[typeString stringByAppendingString:@" message"]];
		
		for (id messageDOMComponent in messageDOMComponents)
		{
			[newParagraph appendChild:messageDOMComponent];
		}
		
		[contentBlock appendChild:newParagraph];
		
		MDChatRosterElement *foundRosterElement = nil;
		if (nickString && [[NSArray arrayWithObjects:@"on_join", @"muc_joined", @"on_leave", @"on_self_leave", nil] containsObject:typeString])
		{
			for (id rosterElement in roster)
			{
				if ([[rosterElement name] isEqualToString:nickString])
				{
					foundRosterElement = rosterElement;
					break;
				}
			}
		}
		
		if (nickString && !foundRosterElement && [[NSArray arrayWithObjects:@"on_join", @"muc_joined", nil] containsObject:typeString])
		{
			[self addNickToRoster:nickString];
		}
		else if (nickString && foundRosterElement && [[NSArray arrayWithObjects:@"on_leave", @"on_self_leave", nil] containsObject:typeString])
		{
			[roster removeObject:foundRosterElement];
			[rosterTableView reloadData];
		}
		
		if ([[NSArray arrayWithObjects:@"muc_joined", @"on_subject", nil] containsObject:typeString])
		{
			if (nickString)
			{
				[self setMyNick:nickString];
			}
			
			updateMyStatus();
		}
		
		if ([[NSArray arrayWithObjects:@"on_message", @"on_private_message", nil] containsObject:typeString])
		{
			if (textString)
			{
				BOOL foundMention = NO;
				for (id word in [textString componentsSeparatedByString:@" "])
				{
					if ([[word stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]] caseInsensitiveCompare:myNick] == NSOrderedSame)
					{
						foundMention = YES;
						break;
					}
				}
				
				if (foundMention)
				{	
					[NSClassFromString(@"GrowlApplicationBridge")
					 notifyWithTitle:nickString ? nickString : @""
					 description:textString
					 notificationName:@"Mention"
					 iconData:nil
					 priority:0
					 isSticky:NO
					 clickContext:@"MessageNotification"];
					
					if (![NSApp isActive])
					{
						[gChatController setNumberOfUnreadMentions:gChatController->numberOfUnreadMentions+1];
					}
				}
				else if (![NSApp isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION] && ![[NSApp delegate] isHaloOpenAndRunningFullscreen])
				{
					[NSClassFromString(@"GrowlApplicationBridge")
					 notifyWithTitle:nickString ? nickString : @""
					 description:textString
					 notificationName:@"MessageReceived"
					 iconData:nil
					 priority:0
					 isSticky:NO
					 clickContext:@"MessageNotification"];
				}
				
				if (![[NSApp delegate] isHaloOpenAndRunningFullscreen] && [[NSUserDefaults standardUserDefaults] boolForKey:CHAT_PLAY_MESSAGE_SOUNDS])
				{
					NSSound *receiveSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CRcv" ofType:@"aif"] byReference:YES];
					[receiveSound play];
					[receiveSound release];
				}
			}
		}
		
		if ([[NSArray arrayWithObjects:@"connection_failed", @"connection_failed_timeout", @"muc_join_failed", @"on_self_leave", nil] containsObject:typeString])
		{
			[self signOff];
		}
	}
	else if ([typeString isEqualToString:@"on_subject"])
	{
		DOMElement *newHeader = [document createElement:@"h1"];
		[newHeader setAttribute:@"class" value:[typeString stringByAppendingString:@" message"]];
		
		for (id messageDOMComponent in messageDOMComponents)
		{
			[newHeader appendChild:messageDOMComponent];
		}
		
		[contentBlock appendChild:newHeader];
	}
	
	[webView display];
	
	int scrollMax = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollHeight - document.documentElement.clientHeight"] intValue];
	int currentScrollPosition = [[webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] intValue];
	
	if ((previousMaxScroll < 0 && scrollMax >= 0) || previousMaxScroll - currentScrollPosition < 5 || [typeString isEqualToString:@"on_subject"])
	{
		[webView scrollToEndOfDocument:nil];
	}
	
	previousMaxScroll = scrollMax;
}

static VALUE processMessage(VALUE self, VALUE type, VALUE message, VALUE nick, VALUE text)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	if (type == Qnil || message == Qnil)
	{
		NSLog(@"Error: type or message was nil on processMessage");
	}
	else
	{
		StringValue(type);
		StringValue(message);
		if (nick != Qnil) StringValue(nick);
		if (text != Qnil) StringValue(text);
		
		NSString *typeString = [[[NSString alloc] initWithBytes:RSTRING_PTR(type) length:RSTRING_LEN(type) encoding:NSUTF8StringEncoding] autorelease];
		
		NSString *messageString = [[[NSString alloc] initWithBytes:RSTRING_PTR(message) length:RSTRING_LEN(message) encoding:NSUTF8StringEncoding] autorelease];
		
		id nickString = nick == Qnil ? [NSNull null] : [[[NSString alloc] initWithBytes:RSTRING_PTR(nick) length:RSTRING_LEN(nick) encoding:NSUTF8StringEncoding] autorelease];
		
		id textString = text == Qnil ?  [NSNull null] : [[[NSString alloc] initWithBytes:RSTRING_PTR(text) length:RSTRING_LEN(text) encoding:NSUTF8StringEncoding] autorelease];
		
		[gChatController performSelector:@selector(processMessageWithArguments:) withObject:[NSArray arrayWithObjects:typeString, messageString, nickString, textString, nil] afterDelay:0.01];
	}
	
	[autoreleasePool release];
	
	return Qnil;
}

- (void)clearAllMessages
{
	DOMDocument *document = [[webView mainFrame] DOMDocument];
	DOMElement *contentBlock = [document getElementById:@"content"];
	
	BOOL done = NO;
	while (!done)
	{
		DOMNodeList *nodeList = [contentBlock childNodes];
		if ([nodeList length] == 0)
		{
			done = YES;
		}
		
		for (unsigned nodeIndex = 0 ; nodeIndex < [nodeList length]; nodeIndex++)
		{
			[contentBlock removeChild:[nodeList item:nodeIndex]];
		}
	}
}

static VALUE clearAllMessages(VALUE self)
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[gChatController performSelector:@selector(clearAllMessages) withObject:nil afterDelay:0.01];
	
	[autoreleasePool release];
	
	return Qnil;
}

static VALUE sendMessageSafely(VALUE data)
{
	const char *messageString = [[[gChatController->textView textStorage] mutableString] UTF8String];
	if (gChatController->chatting != Qnil && gChatController->chatTimer && rb_funcall(gChatController->chatting, rb_intern("send_message"), 1, rb_str_new2(messageString)) == Qtrue)
	{
		[[[gChatController->textView textStorage] mutableString] setString:@""];
		[gChatController adjustTextView];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:CHAT_PLAY_MESSAGE_SOUNDS] && *messageString != '/')
		{
			NSSound *sendSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CSnd" ofType:@"aif"] byReference:YES];
			[sendSound play];
			[sendSound release];
		}
	}
	
	return Qnil;
}

- (void)sendMessage
{
	int exceptionState = 0;
	rb_protect(sendMessageSafely, Qnil, &exceptionState);
	if (exceptionState != 0)
	{
		NSLog(@"Error: Failed to send message");
	}
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[rosterTableView setDoubleAction:@selector(joinGameFromRoster:)];
    
	[webView setDrawsBackground:NO];
    [webView setUIDelegate:self];
    [webView setFrameLoadDelegate:self];
	
	[[webView windowScriptObject] setValue:self forKey:NSStringFromClass([self class])];
	
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:nil];
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
}

- (IBAction)joinGameFromRoster:(id)sender
{
	if ([rosterTableView selectedRow] >= 0 && [rosterTableView selectedRow] < [roster count])
	{
		MDChatRosterElement *rosterElement = [roster objectAtIndex:[rosterTableView selectedRow]];
		if (![[rosterElement name] isEqualToString:myNick] && [[rosterElement status] hasPrefix:MD_STATUS_PREFIX])
		{
			NSArray *statusComponents = [[rosterElement status] componentsSeparatedByString:@":"];
			if ([statusComponents count] >= 3)
			{
				NSString *ipAddress = [statusComponents objectAtIndex:1];
				int portNumber = [[statusComponents objectAtIndex:2] intValue];
				for (id server in [[NSApp delegate] servers])
				{
					if ([[server ipAddress] isEqualToString:ipAddress] && [server portNumber] == portNumber)
					{
						[[NSApp delegate] joinServer:server];
						break;
					}
				}
			}
		}
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self signOn];
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	
	if (signedOnForFirstTime && !chatTimer)
	{
		[self signOn];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] == [self window])
	{
		[self signOff];
	}
}

static VALUE pollSafely(VALUE data)
{
	// Allow ruby's interpreter to process events
	rb_funcall(gChatController->chatting, rb_intern("poll"), 0);
	
	return Qnil;
}

- (void)updateChat:(id)unused
{
	if (chatting != Qnil)
	{
		int exceptionState = 0;
		rb_protect(pollSafely, Qnil, &exceptionState);
	}
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	if (splitView == chatSplitView || (splitView == rosterSplitView && subview == chatSplitView))
	{
		return NO;
	}
	
	return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == chatSplitView)
	{
		return proposedMinimumPosition + 150;
	}

	return proposedMinimumPosition + 150;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == chatSplitView)
	{
		return proposedMaximumPosition - 20;
	}
	
	return proposedMaximumPosition - 115;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	return splitView == chatSplitView;
}

- (void)adjustScrollingAndTextView
{
	[self adjustTextView];
	[webView scrollToEndOfDocument:nil];
	previousMaxScroll = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollHeight - document.documentElement.clientHeight"] intValue];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	if ([aNotification object] == rosterSplitView)
	{
		[self adjustScrollingAndTextView];
	}
}

- (void)windowDidResize:(NSNotification *)notification
{
	if ([notification object] == [self window])
	{
		[self adjustScrollingAndTextView];
	}
}

- (void)adjustTextView
{
	NSView *bottomSubview = [[chatSplitView subviews] objectAtIndex:1];
	
	NSLayoutManager *layoutManager = [textView layoutManager];
	NSTextContainer *textContainer = [textView textContainer];
	
	// Force layout
	[layoutManager ensureLayoutForBoundingRect:bottomSubview.frame inTextContainer:textContainer];
	NSRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
	
	// Calculate height somehow
	CGFloat calculatedHeight = usedRect.size.height + 4;
	[bottomSubview setFrameSize:NSMakeSize(bottomSubview.frame.size.width, calculatedHeight)];
}

- (void)textDidChange:(NSNotification *)notification
{
	[self adjustTextView];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)selector
{
	if (selector == @selector(insertNewline:))
	{
		[self sendMessage];
		return YES;
	}
	else if (selector == @selector(insertTabIgnoringFieldEditor:) || selector == @selector(insertTab:))
	{
		[aTextView complete:nil];
		return YES;
	}
	
	return NO;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil; // disable contextual menu for the webView
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    return YES; // disallow everything
}

// Make links open in user's web browser
// http://stackoverflow.com/questions/4530590/opening-webview-links-in-safari
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id )listener
{
	NSString *host = [[request URL] host];
	if (host)
	{
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	else
	{
		[listener use];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [roster count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if (rowIndex >= 0 && (NSUInteger)rowIndex < [roster count])
	{
		CGFloat systemFontSize = [[NSFont systemFontOfSize:0] pointSize];
		
		static NSImage *inChatImage = nil;
		if (!inChatImage)
		{
			inChatImage = [[NSImage imageNamed:@"in_chat_icon.pdf"] copy];
			[inChatImage setSize:NSMakeSize(systemFontSize, systemFontSize)];
		}
		
		static NSImage *inGameImage = nil;
		if (!inGameImage)
		{
			inGameImage = [[NSImage imageNamed:@"game_icon.pdf"] copy];
			[inGameImage setSize:NSMakeSize(systemFontSize, systemFontSize)];
		}
		
		MDChatRosterElement *rosterElement = [roster objectAtIndex:rowIndex];
		if ([[tableColumn identifier] isEqualToString:@"player"])
		{
			NSMutableAttributedString *userItem = [[[NSMutableAttributedString alloc] init] autorelease];
			
			BOOL isInGame = [[rosterElement status] hasPrefix:MD_STATUS_PREFIX];
			
			NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
			id cell = [attachment attachmentCell];
			[cell setImage:isInGame ? inGameImage : inChatImage];
			NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:attachment];
			[userItem appendAttributedString:imageString];
			[userItem appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [rosterElement name]]] autorelease]];
			
			if (isInGame)
			{
				NSArray *statusComponents = [[rosterElement status] componentsSeparatedByString:@":"];
				if ([statusComponents count] >= 3)
				{
					NSString *ipAddress = [statusComponents objectAtIndex:1];
					int portNumber = [[statusComponents objectAtIndex:2] intValue];
					
					MDServer *foundServer = nil;
					for (MDServer *server in [[NSApp delegate] servers])
					{
						if ([[server ipAddress] isEqualToString:ipAddress] && [server portNumber] == portNumber)
						{
							foundServer = server;
							break;
						}
					}
					
					if (foundServer)
					{
						NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:systemFontSize / 1.5], NSFontAttributeName, nil];
						NSAttributedString *serverName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [foundServer name]] attributes:attributes];
						[userItem appendAttributedString:serverName];
						[serverName release];
					}
				}
			}
			return userItem;
		}
	}
	
	return nil;
}

- (NSArray *)textView:(NSTextView *)aTextView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	NSString *characters = [[[aTextView textStorage] mutableString] substringWithRange:charRange];
	NSMutableArray *newWords = [NSMutableArray array];
	
	BOOL foundMyNick = NO;
	for (id rosterElement in roster)
	{
		if ([[[rosterElement name] lowercaseString] hasPrefix:[characters lowercaseString]])
		{
			if ([[rosterElement name] isEqualToString:myNick])
			{
				foundMyNick = YES;
			}
			else
			{
				if (charRange.location == 0)
				{
					[newWords addObject:[[rosterElement name] stringByAppendingString:@": "]];
				}
				else
				{
					[newWords addObject:[rosterElement name]];
				}
			}
		}
	}
	
	if (foundMyNick)
	{
		if (charRange.location == 0)
		{
			[newWords addObject:[myNick stringByAppendingString:@": "]];
		}
		else
		{
			[newWords addObject:myNick];
		}
	}
	
	return newWords;
}

@end
