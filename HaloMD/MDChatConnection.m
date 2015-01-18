/*
 * Copyright (c) 2014, Null <foo.null@yahoo.com>
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

#import "MDChatConnection.h"

#import "XMPPJID.h"
#import "XMPPAnonymousAuthentication.h"
#import "XMPPStream.h"
#import "XMPPRoomMemoryStorage.h"
#import "XMPPRoom.h"
#import "XMPPMessage+XEP0045.h"

#define XMPP_HOST_NAME @"gekko.macgamingmods.com"
#define XMPP_ROOM_HOST @"conference.gekko.macgamingmods.com"
#define XMPP_ROOM_NAME @"halomd"
#define XMPP_RESOURCE @"halomd"
#define XMPP_CONNECT_TIMEOUT 15 // seconds

@interface MDChatConnection ()

@property (nonatomic) XMPPStream *stream;
@property (nonatomic) XMPPRoom *room;
@property (nonatomic) NSUInteger chancesLeftToJoin;

@end

@implementation MDChatConnection

- (id)initWithNickname:(NSString *)nickname userIdentifier:(NSString *)userIdentifier delegate:(id <MDChatConnectionDelegate>)delegate;
{
	self = [super init];
	if (self != nil)
	{
		_nickname = [nickname copy];
		_userIdentifier = [userIdentifier copy];
		_delegate = delegate;
		_chancesLeftToJoin = 5;
	}
	return self;
}

- (void)dealloc
{
	[_stream disconnect];
}

- (NSString *)dateFormat
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%I:%M:%S" allowNaturalLanguage:NO];
	//NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	//[formatter setDateFormat:@"%I:%M:%S"];
	return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)prependCurrentDateToMessage:(NSString *)message
{
	return [NSString stringWithFormat:@"%@ %@", [self dateFormat], message];
}

- (BOOL)joinRoom
{
	if (!_stream.isConnected)
	{
		[_delegate processMessage:[self prependCurrentDateToMessage:@"Connecting to server..."] type:@"connection_initiating" nickname:nil text:nil];
		
		_stream = [[XMPPStream alloc] init];
		[_stream addDelegate:self delegateQueue:dispatch_get_main_queue()];
		_stream.hostName = XMPP_HOST_NAME;
		_stream.myJID = [XMPPJID jidWithUser:_userIdentifier domain:XMPP_HOST_NAME resource:XMPP_RESOURCE];
		
		NSError *error = nil;
		BOOL success = [_stream connectWithTimeout:XMPP_CONNECT_TIMEOUT error:&error];
		if (!success)
		{
			NSLog(@"Error signing on: %@", error);
			return NO;
		}
	}
	
	[_room joinRoomUsingNickname:_nickname history:nil];
	
	return YES;
}

- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
	NSLog(@"Error: Timed out connecting to server..");
}

- (void)leaveRoom
{
	if (self.isInRoom)
	{
		[_room leaveRoom];
	}
}

- (BOOL)isInRoom
{
	return _room.isJoined;
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	NSError *error = nil;
	// -[XMPPStream authenticateAnonymously:] which uses SASL ANONYMOUS authentication may use a randomized JID from the server, which is not desirable
	BOOL operationInProgress = [_stream authenticate:[[XMPPDigestMD5Authentication alloc] initWithStream:_stream password:@"password"] error:&error];
	if (!operationInProgress)
	{
		NSLog(@"We failed to authenticate..: %@", error);
		[_delegate processMessage:[self prependCurrentDateToMessage:@"Failed to connect to the server..."] type:@"connection_failed" nickname:nil text:nil];
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	NSLog(@"Error: Disconnected: %@", error);
	_stream = nil;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	_room = [[XMPPRoom alloc] initWithRoomStorage:[[XMPPRoomMemoryStorage alloc] init] jid:[XMPPJID jidWithUser:XMPP_ROOM_NAME domain:XMPP_ROOM_HOST resource:XMPP_RESOURCE]];
	
	[_room addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[_room activate:_stream];
	
	[self joinRoom];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	NSLog(@"Error: Failed to authenticate: %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	NSLog(@"Received xmpp error: %@", error);
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
	_nickname = [_room.myNickname copy];
	[_delegate processMessage:[self prependCurrentDateToMessage:@"You joined the chat..."] type:@"muc_joined" nickname:_nickname text:nil];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
	NSString *senderName = occupantJID.resource;
	
	[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"<%@> joined", senderName]] type:@"on_join" nickname:senderName text:presence.status];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
	NSString *senderName = occupantJID.resource;
	NSString *messageType = ([senderName isEqualToString:_nickname]) ? @"on_self_leave" : @"on_leave";
	
	[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"<%@> left", senderName]] type:messageType nickname:senderName text:presence.status];
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
	NSString *senderName = occupantJID.resource;
	[_delegate processMessage:[self prependCurrentDateToMessage:@""] type:@"on_join" nickname:senderName text:presence.status];
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
	NSString *senderName = occupantJID.resource;
	
	if ([message isGroupChatMessageWithSubject])
	{
		_subject = [message.subject copy];
		
		[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"Topic is: %@", message.subject]] type:@"on_subject" nickname:nil text:message.subject];
	}
	else if ([message isGroupChatMessageWithBody])
	{
		NSString *messageType = ([senderName isEqualToString:_nickname]) ? @"my_message" : @"on_message";
		
		[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"<%@> %@", senderName, message.body]] type:messageType nickname:senderName text:message.body];
	}
}

- (BOOL)sendMessage:(NSString *)message
{
	if (self.isInRoom)
	{
		[_room sendMessageWithBody:message];
		return YES;
	}
	
	return NO;
}

- (void)sendPrivateMessage:(NSString *)message toUser:(NSString *)nickname
{
	XMPPMessage *xmppMessage = [XMPPMessage message];
	
	[xmppMessage addBody:message];
	[xmppMessage addAttributeWithName:@"type" stringValue:@"chat"];
	[xmppMessage addAttributeWithName:@"to" stringValue:[[XMPPJID jidWithUser:XMPP_ROOM_NAME domain:XMPP_ROOM_HOST resource:nickname] full]];
	
	[_stream sendElement:xmppMessage];
	
	[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"<Private message to %@>: %@", nickname, message]] type:@"my_private_message" nickname:_nickname text:message];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if ([message isChatMessageWithBody])
	{
		NSString *sender = message.from.resource;
		[_delegate processMessage:[self prependCurrentDateToMessage:[NSString stringWithFormat:@"Private: <%@> %@", sender, message.body]] type:@"on_private_message" nickname:sender text:message.body];
	}
}

- (void)setStatus:(NSString *)status
{
	XMPPPresence *presence = [XMPPPresence presence];
	
	[presence addAttributeWithName:@"from" stringValue:_stream.myJID.full];
	[presence addAttributeWithName:@"to" stringValue:[[XMPPJID jidWithUser:XMPP_ROOM_NAME domain:XMPP_ROOM_HOST resource:_nickname] full]];
	[presence addAttributeWithName:@"id" stringValue:[_stream generateUUID]];
	
	[presence addChild:[NSXMLElement elementWithName:@"status" stringValue:status]];
	
	// have to notify ourselves of our own status update
	[_delegate processMessage:[self prependCurrentDateToMessage:@""] type:@"on_join" nickname:_nickname text:status];
	
	[_stream sendElement:presence];
}

@end
