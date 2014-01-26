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
//  AppDelegate.h
//  HaloMD
//
//  Created by null on 1/26/12.
//

#import <Cocoa/Cocoa.h>

@class MDInspectorController;
@class MDModsController;
@class MDServer;
@class DSClickableURLTextField;
@class MDChatWindowController;
@class MDGameFavoritesWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	IBOutlet NSButton *launchButton;
	IBOutlet NSButton *joinButton;
	IBOutlet NSButton *refreshButton;
	IBOutlet NSTableView *serversTableView;
	IBOutlet NSWindow *serverPasswordWindow;
	IBOutlet NSTextField *serverPasswordTextField;
	IBOutlet DSClickableURLTextField *statusTextField;
	IBOutlet NSProgressIndicator *installProgressIndicator;
	IBOutlet NSButton *chatButton;
	IBOutlet MDChatWindowController *chatWindowController;
	IBOutlet NSWindow *window;
	
	IBOutlet NSTextField *haloNameTextField;
	IBOutlet NSWindow *haloNameWindow;
	
	IBOutlet MDInspectorController *inspectorController;
	IBOutlet MDModsController *modsController;
	
	MDGameFavoritesWindowController *_favoritesWindowController;
	
	NSTimer *queryTimer;
	NSTimer *refreshVisibleServersTimer;
	NSMutableArray *serversArray;
	NSMutableArray *waitingServersArray;
	NSMutableArray *hiddenServersArray;
	NSString *myIPAddress;
	NSTask *haloTask;
	BOOL isInstalled;
	BOOL usingServerCache;
	BOOL sleeping;
	
	MDServer *inGameServer;
	
	NSArray *openFiles;
	BOOL shiftKeyHeldDown;
	BOOL isRelaunchingHalo;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, nonatomic) NSMutableArray *serversArray;
@property (copy, nonatomic) NSString *myIPAddress;
@property (retain, nonatomic) NSArray *openFiles;
@property (readonly) NSProgressIndicator *installProgressIndicator;
@property (readonly) BOOL isInstalled;
@property (assign) BOOL usingServerCache;
@property (nonatomic, retain) MDServer *inGameServer;

- (NSString *)applicationSupportPath;
- (NSString *)resourceGameDataPath;

- (NSString *)machineSerialKey;

- (NSArray *)servers;
- (MDServer *)selectedServer;

- (void)joinServer:(MDServer *)server;

- (BOOL)isHaloOpenAndRunningFullscreen;
- (BOOL)isHaloOpen;
- (void)terminateHaloInstances;

- (void)updateHiddenServers;
- (BOOL)isQueryingServers;

- (void)setStatusWithoutWait:(id)message;
- (void)setStatus:(id)message withWait:(NSTimeInterval)waitTimeInterval;
- (void)setStatus:(id)message;

- (NSString *)profileName;
- (NSString *)serialKey;
- (NSString *)randomSerialKey;

- (IBAction)help:(id)sender;

- (IBAction)launchHalo:(id)sender;
- (IBAction)joinGame:(id)sender;
- (IBAction)refreshServer:(id)sender;
- (IBAction)refreshServers:(id)sender;

- (IBAction)serverPasswordJoin:(id)sender;
- (IBAction)serverPasswordCancel:(id)sender;

- (IBAction)pickHaloName:(id)sender;
- (IBAction)pickHaloNameRandom:(id)sender;

- (IBAction)showChatWindow:(id)sender;

@end
