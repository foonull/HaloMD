//
//  AppDelegate.h
//  HaloMD
//
//  Created by null on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Ruby/ruby.h>

@class MDInspectorController;
@class MDModsController;
@class MDServer;
@class DSClickableURLTextField;
@class MDChatWindowController;

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
	
	NSTimer *queryTimer;
	NSTimer *refreshVisibleServersTimer;
	NSMutableArray *serversArray;
	NSMutableArray *waitingServersArray;
	NSMutableArray *hiddenServersArray;
	NSString *myIPAddress;
	NSTask *haloTask;
	VALUE networking;
	BOOL isInstalled;
	BOOL usingServerCache;
	
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

VALUE requireWrapper(VALUE path);

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
