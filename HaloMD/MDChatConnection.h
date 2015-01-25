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

#import <Foundation/Foundation.h>

@protocol MDChatConnectionDelegate <NSObject>

- (void)processMessage:(NSString *)messageString type:(NSString *)typeString nickname:(NSString *)nickString text:(NSString *)textString;

@end

@interface MDChatConnection : NSObject

@property (nonatomic, readonly, assign) id <MDChatConnectionDelegate> delegate;
@property (nonatomic, readonly) NSString *nickname;
@property (nonatomic, readonly) NSString *userIdentifier;
@property (nonatomic, readonly) NSString *subject;
@property (nonatomic) BOOL showJIDOnBan;

- (id)initWithNickname:(NSString *)nickname userIdentifier:(NSString *)userIdentifier delegate:(id <MDChatConnectionDelegate>)delegate;

- (BOOL)sendMessage:(NSString *)message;
- (void)sendPrivateMessage:(NSString *)message toUser:(NSString *)nickname;

- (BOOL)joinRoom;
- (void)leaveRoom;
- (BOOL)isInRoom;
- (void)disconnect;

- (void)reauthenticateWithUserID:(NSString *)newUserID;

- (void)setStatus:(NSString *)status;

@end
