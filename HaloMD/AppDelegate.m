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
//  AppDelegate.m
//  HaloMD
//
//  Created by null on 1/26/12.
//

#import "AppDelegate.h"
#import "MDServer.h"
#import "MDPlayer.h"
#import "MDInspectorController.h"
#import "MDModsController.h"
#import "MDNetworking.h"
#import "MDHyperLink.h"
#import "keygen.h"
#import "DSClickableURLTextField.h"
#import "MDChatWindowController.h"
#import "MDGameFavoritesWindowController.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <Growl/Growl.h>

@interface AppDelegate (Private)

- (void)resumeQueryTimer;
- (MDChatWindowController *)chatWindowController;

@end

@implementation AppDelegate

@synthesize window;
@synthesize serversArray;
@synthesize myIPAddress;
@synthesize openFiles;
@synthesize installProgressIndicator;
@synthesize isInstalled;
@synthesize usingServerCache;
@synthesize inGameServer;

#define HALO_MD_IDENTIFIER @"com.null.halominidemo"
#define HALO_MD_IDENTIFIER_FILE [HALO_MD_IDENTIFIER stringByAppendingString:@".plist"]
#define HALO_FILE_VERSIONS_KEY @"HALO_FILE_VERSIONS_KEY"
#define HALO_FIX_SCORE_KEY @"HALO_FIX_SCORE_KEY"
#define HALO_GAMES_PASSWORD_KEY @"HALO_GAMES_PASSWORD_KEY"
#define HALO_LOBBY_GAMES_CACHE_KEY @"HALO_LOBBY_GAMES_CACHE_KEY2"

static NSDictionary *expectedVersionsDictionary = nil;
+ (void)initialize
{
	// This test is necessary since initialize can be called more than once if a subclass of AppDelegate is created
	// Currently, a subclass is created because in another class, I'm using KVO on a property of AppDelegate
	if (self == [AppDelegate class])
	{
		expectedVersionsDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithInteger:18], @"Contents/MacOS/Halo",
									   [NSNumber numberWithInteger:3], @"Contents/Resources/HaloAppIcon.icns",
									   [NSNumber numberWithInteger:2], @"Contents/Resources/HaloDataIcon.icns",
									   [NSNumber numberWithInteger:2], @"Contents/Resources/HaloDocIcon.icns",
									   [NSNumber numberWithInteger:24], @"Maps/bloodgulch.map",
									   [NSNumber numberWithInteger:24], @"Maps/barrier.map",
									   [NSNumber numberWithInteger:28], @"Maps/ui.map",
									   [NSNumber numberWithInteger:8], @"Maps/bitmaps.map",
									   [NSNumber numberWithInteger:26], @"Maps/crossing.map",
									   [NSNumber numberWithInteger:3], @"Maps/magiciswaiting.map",
									   nil] retain];
		
		NSMutableArray *defaultVersionNumbers = [NSMutableArray array];
		for (int index = 0; index < [expectedVersionsDictionary count]; index++)
		{
			[defaultVersionNumbers addObject:[NSNumber numberWithInteger:0]];
		}
		
		NSMutableDictionary *registeredDefaults = [NSMutableDictionary dictionary];
		[registeredDefaults setObject:[NSDictionary dictionaryWithObjects:defaultVersionNumbers forKeys:[expectedVersionsDictionary allKeys]]
							   forKey:HALO_FILE_VERSIONS_KEY];
		
		[registeredDefaults setObject:[NSDictionary dictionary]
							   forKey:HALO_GAMES_PASSWORD_KEY];
		
		[registeredDefaults setObject:@""
							   forKey:MODS_LIST_DOWNLOAD_TIME_KEY];
		
		[registeredDefaults setObject:[NSArray arrayWithObjects:@"23.94.32.156:2301", @"198.23.244.145:2302", @"66.225.231.168:2306", @"162.217.250.28:2300", @"10.1.1.1:49149:3425", nil] forKey:HALO_LOBBY_GAMES_CACHE_KEY];
		
		[registeredDefaults setObject:[NSNumber numberWithBool:NO] forKey:HALO_FIX_SCORE_KEY];
		
		[registeredDefaults setObject:[NSNumber numberWithBool:YES] forKey:CHAT_PLAY_MESSAGE_SOUNDS];
		[registeredDefaults setObject:[NSNumber numberWithBool:NO] forKey:CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:registeredDefaults];
	}
}

// http://developer.apple.com/library/mac/#technotes/tn1103/_index.html
- (void)copySerialNumber:(CFStringRef *)serialNumber
{
	if (serialNumber != NULL)
	{
		*serialNumber = NULL;
		io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
		
		if (platformExpert)
		{
			CFTypeRef serialNumberAsCFString =
			IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
			if (serialNumberAsCFString)
			{
				*serialNumber = serialNumberAsCFString;
			}
			
			IOObjectRelease(platformExpert);
		}
	}
}

- (NSString *)machineSerialKey
{
	CFStringRef serialKey = NULL;
	[self copySerialNumber:&serialKey];
	return [(NSString *)serialKey autorelease];
}

- (id)init
{
	self = [super init];
	if (self)
	{	
		serversArray = [[NSMutableArray alloc] init];
		waitingServersArray = [[NSMutableArray alloc] init];
		hiddenServersArray = [[NSMutableArray alloc] init];
		
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
		
		if ([[NSBundle class] respondsToSelector:@selector(bundleWithURL:)]) // easy way to tell if user is on >= 10.6
		{
			NSString *growlPath = [[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"Growl"] stringByAppendingPathExtension:@"framework"];
			[[NSBundle bundleWithPath:growlPath] load];
			[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:(id<GrowlApplicationBridgeDelegate>)self];
		}
	}
	
	return self;
}

- (IBAction)goFullScreen:(id)sender
{
	if ([[self window] isKeyWindow])
	{
		[[self window] toggleFullScreen:nil];
	}
	else if (chatWindowController && [[[self chatWindowController] window] isKeyWindow])
	{
		[[[self chatWindowController] window] toggleFullScreen:nil];
	}
}

- (void)growlNotificationWasClicked:(id)clickContext
{
	if (modsController && [clickContext isEqualToString:@"ModDownloaded"])
	{
		[[self window] makeKeyAndOrderFront:nil];
	}
	else if (chatWindowController && [clickContext isEqualToString:@"MessageNotification"])
	{
		[self showChatWindow:nil];
	}
}

- (NSArray *)servers
{
	return serversArray;
}

- (MDServer *)selectedServer
{
	MDServer *selectedServer = nil;
	
	if ([serversTableView selectedRow] >= 0 && [serversTableView selectedRow] < [serversArray count])
	{
		selectedServer = [serversArray objectAtIndex:[serversTableView selectedRow]];
	}
	
	return selectedServer;
}

- (BOOL)isQueryingServers
{
	return (queryTimer  != nil);
}

- (IBAction)help:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://halomd.net/help"]];
}

- (NSString *)libraryPath
{
	return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (NSString *)preferencesPath
{
	return [[[self libraryPath] stringByAppendingPathComponent:@"Preferences"] stringByAppendingPathComponent:HALO_MD_IDENTIFIER_FILE];
}

- (NSString *)applicationSupportPath
{
	return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HaloMD"];
}

- (NSString *)resourceDataPath
{
	return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Data"];
}

- (NSString *)resourceAppPath
{
	return [[self resourceDataPath] stringByAppendingPathComponent:@"DoNotTouchOrModify2"];
}

- (NSString *)resourceGameDataPath
{
	return [[self resourceDataPath] stringByAppendingPathComponent:@"DoNotTouchOrModify"];
}

- (void)addOpenFiles
{
	for (id file in openFiles)
	{
		if ([[file pathExtension] isEqualToString:@"map"])
		{
			[modsController addModAtPath:file];
		}
		else if ([[file pathExtension] isEqualToString:@"mdplugin"])
		{
			[modsController addPluginAtPath:file preferringEnabledState:YES];
		}
	}
	
	[self setOpenFiles:nil];
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames
{
	[self setOpenFiles:filenames];
	
	if ([modsController isInitiated])
	{
		[self addOpenFiles];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)theMenuItem
{
	if ([theMenuItem action] == @selector(goFullScreen:))
	{
		if (![[self window] isKeyWindow] && (!chatWindowController || ![[[self chatWindowController] window] isKeyWindow]))
		{
			return NO;
		}
		
		if (![[self window] respondsToSelector:@selector(toggleFullScreen:)])
		{
			return NO;
		}
	}
	if ([theMenuItem action] == @selector(refreshServer:))
	{
		if (![self selectedServer] || ![[self window] isVisible])
		{
			return NO;
		}
	}
	else if ([theMenuItem action] == @selector(refreshServers:))
	{
		if (![refreshButton isEnabled] || ![[self window] isVisible])
		{
			return NO;
		}
	}
	else if ([theMenuItem action] == @selector(joinGame:))
	{
		if (![joinButton isEnabled] || ![[self window] isVisible])
		{
			return NO;
		}
	}
	else if ([theMenuItem action] == @selector(toggleMessageSounds:))
	{
		[theMenuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:CHAT_PLAY_MESSAGE_SOUNDS]];
	}
	else if ([theMenuItem action] == @selector(toggleMessageReceiveNotifications:))
	{
		[theMenuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION]];
	}
	
	return YES;
}

- (IBAction)toggleMessageSounds:(id)sender
{
	BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:CHAT_PLAY_MESSAGE_SOUNDS];
	[[NSUserDefaults standardUserDefaults] setBool:!state forKey:CHAT_PLAY_MESSAGE_SOUNDS];
}

- (IBAction)toggleMessageReceiveNotifications:(id)sender
{
	BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION];
	[[NSUserDefaults standardUserDefaults] setBool:!state forKey:CHAT_SHOW_MESSAGE_RECEIVE_NOTIFICATION];
}

- (void)setUpInitFile:(NSString *)command
{
	NSString *templateInitPath = [[[self applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"template_init.txt"];
	NSString *initPath = [[[self applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"init.txt"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:initPath])
	{
		[[NSFileManager defaultManager] removeItemAtPath:initPath
												   error:NULL];
	}
	
	NSMutableString *templateInitString = [NSMutableString stringWithContentsOfFile:templateInitPath
																		   encoding:NSUTF8StringEncoding
																			  error:NULL];
	
	if (!templateInitString)
	{
		NSLog(@"Failed to create templateInitString");
		templateInitString = [NSMutableString string];
	}
	
	if (command)
	{
		[templateInitString appendFormat:@"\n%@", command];
	}
	
	[templateInitString writeToFile:initPath
						 atomically:YES
						   encoding:NSUTF8StringEncoding
							  error:NULL];
}

- (void)startHaloTask
{
	NSBundle *haloBundle = [NSBundle bundleWithPath:[[self applicationSupportPath] stringByAppendingPathComponent:@"HaloMD.app"]];
	NSString *launchPath = [haloBundle executablePath];
	
	[haloTask release];
	haloTask = [[NSTask alloc] init];
	
	@try
	{
#ifndef __ppc__
		[haloTask setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"MDOverrides.dylib"], @"DYLD_INSERT_LIBRARIES", [[NSBundle mainBundle] builtInPlugInsPath], @"MD_BUILTIN_PLUGIN_DIRECTORY", [self resourceGameDataPath], @"MD_STOCK_GAME_DATA_DIRECTORY", nil]];
#endif
		[haloTask setLaunchPath:launchPath];
		[haloTask setArguments:[NSArray array]];
		[haloTask launch];
	}
	@catch (NSException *exception)
	{
		NSLog(@"Halo Task Exception: %@, %@", [exception name], [exception reason]);
	}
}

- (IBAction)launchHalo:(id)sender
{
	[modsController setJoiningServer:nil];
	
	Class runningApplicationClass = NSClassFromString(@"NSRunningApplication");
	NSArray *runningHaloApplications = [runningApplicationClass runningApplicationsWithBundleIdentifier:HALO_MD_IDENTIFIER];
	if ([haloTask isRunning] || [runningHaloApplications count] > 0)
	{
		if (runningApplicationClass)
		{
			// HaloMD is already running, just make it active
			NSRunningApplication *haloApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:[haloTask processIdentifier]];
			if (!haloApplication && [runningHaloApplications count] > 0)
			{
				haloApplication = [runningHaloApplications objectAtIndex:0];
			}
			
			[haloApplication activateWithOptions:NSApplicationActivateAllWindows];
		}
		else
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[[self applicationSupportPath] stringByAppendingPathComponent:@"HaloMD.app"]]];
		}
	}
	else
	{
		[self setUpInitFile:nil];
		[self startHaloTask];
		[self setInGameServer:nil];
	}
}

- (BOOL)isHaloOpenAndRunningFullscreen
{	
	if ([self isHaloOpen] && [[NSFileManager defaultManager] fileExistsAtPath:[self preferencesPath]])
	{
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[self preferencesPath]];
		NSData *data = [dictionary objectForKey:@"Graphics Options"];
		if ([data length] >= 0x14+sizeof(int8_t))
		{
			return *((int8_t *)([data bytes] + 0x14)) == 0;
		}
	}
	
	return NO;
}

- (BOOL)isHaloOpen
{
	if ([haloTask isRunning])
	{
		return YES;
	}
	
	if (NSClassFromString(@"NSRunningApplication"))
	{
		if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:HALO_MD_IDENTIFIER] count] > 0)
		{
			return YES;
		}
	}
	else
	{
		NSArray *launchedApplications = [[NSWorkspace sharedWorkspace] launchedApplications];
		for (NSDictionary *applicationDictionary in launchedApplications)
		{
			if ([[applicationDictionary objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:HALO_MD_IDENTIFIER])
			{
				return YES;
			}
		}
	}
	
	return NO;
}

- (void)terminateHaloInstances
{
	int taskProcessID = [haloTask processIdentifier];
	if ([haloTask isRunning])
	{
		[haloTask terminate];
		[haloTask release];
		haloTask = nil;
	}
	
	if (NSClassFromString(@"NSRunningApplication"))
	{
		for (NSRunningApplication *runningApplication in [NSRunningApplication runningApplicationsWithBundleIdentifier:HALO_MD_IDENTIFIER])
		{
			if ([runningApplication processIdentifier] != taskProcessID)
			{
				// using forceTerminate instead of terminate as sending terminate while Halo is in the graphics window may cause it to start up rather than terminate, very odd
				[runningApplication forceTerminate];
			}
		}
	}
	else
	{
		NSArray *launchedApplications = [[NSWorkspace sharedWorkspace] launchedApplications];
		for (NSDictionary *applicationDictionary in launchedApplications)
		{
			if ([[applicationDictionary objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:HALO_MD_IDENTIFIER])
			{
				int applicationProcessID = [[applicationDictionary objectForKey:@"NSApplicationProcessIdentifier"] intValue];
				if (applicationProcessID != taskProcessID)
				{
					kill(applicationProcessID, SIGKILL);
				}
			}
		}
	}
}

- (void)requireUserToTerminateHalo
{
	while ([self isHaloOpen])
	{
		NSRunAlertPanel(@"Update requires Halo to be closed",
						@"Please quit Halo in order to update it.",
						@"OK", nil, nil);
	}
}

- (void)connectToServerWithArguments:(NSArray *)arguments
{
	MDServer *server = [arguments objectAtIndex:0];
	NSString *password = [arguments objectAtIndex:1];
	
	if ([self isHaloOpen])
	{
		if (!isRelaunchingHalo && NSRunAlertPanel(@"HaloMD is already running",
							@"HaloMD will relaunch in order to join this game.",
							@"OK", @"Cancel", nil) != NSOKButton)
		{
			return;
		}
		
		if (!isRelaunchingHalo)
		{
			[self terminateHaloInstances];
		}
		
		[self performSelector:@selector(connectToServerWithArguments:) withObject:arguments afterDelay:0.1];
		isRelaunchingHalo = YES;
		return;
	}
	
	if (![[server map] isEqualToString:MODDED_SLOT_IDENTIFIER] || ![[MDServer formalizedMapsDictionary] objectForKey:[server map]])
	{
		[modsController enableModWithMapIdentifier:[server map]];
	}
	
	[self setUpInitFile:[NSString stringWithFormat:@"connect %@:%d \"%@\"", [server ipAddress], [server portNumber], password]];
	[self startHaloTask];
	
	[self setInGameServer:server];
	
	isRelaunchingHalo = NO;
}

- (void)connectToServer:(MDServer *)server password:(NSString *)password
{
	[self connectToServerWithArguments:[NSArray arrayWithObjects:server, password, nil]];
}

- (IBAction)serverPasswordJoin:(id)sender
{
	MDServer *server = [self selectedServer];
	if (server)
	{
		if ([server passwordProtected])
		{
			NSMutableDictionary *passwordsDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:HALO_GAMES_PASSWORD_KEY]];
			
			if (passwordsDictionary)
			{
				[passwordsDictionary setObject:[serverPasswordTextField stringValue] forKey:[server ipAddress]];
				[[NSUserDefaults standardUserDefaults] setObject:passwordsDictionary forKey:HALO_GAMES_PASSWORD_KEY];
			}
			
			[self connectToServer:server
						 password:[serverPasswordTextField stringValue]];
		}
	}
	
	[self serverPasswordCancel:nil];
}

- (IBAction)serverPasswordCancel:(id)sender
{
	[NSApp endSheet:serverPasswordWindow];
	[serverPasswordWindow close];
}

- (void)_setStatus:(NSTimer *)timer
{
	id message = [timer userInfo];
	
	if ([message isKindOfClass:[NSString class]])
	{
		[statusTextField setStringValue:message];
	}
	else if ([message isKindOfClass:[NSAttributedString class]])
	{
		[statusTextField setAttributedStringValue:message];
	}
	else if (isInstalled && ![modsController currentDownloadingMapIdentifier]) // presumably, message is nil
	{
		int numberOfValidServers = 0;
		BOOL allServersGaveUp = YES;
		for (MDServer *server in serversArray)
		{
			if ([server valid])
			{
				numberOfValidServers++;
			}
			else if (![server outOfConnectionChances])
			{
				allServersGaveUp = NO;
			}
		}
		
		if (!self.usingServerCache)
		{
			if (numberOfValidServers == 0)
			{
				if (allServersGaveUp)
				{
					[statusTextField setStringValue:@"No games found. Why not try creating one?"];
				}
			}
			else
			{
				[statusTextField setStringValue:[NSString stringWithFormat:@"Found %d game%@.", numberOfValidServers, numberOfValidServers == 1 ? @"" : @"s"]];
			}
		}
	}
	
	[message release];
}

- (void)setStatusWithoutWait:(id)message
{
	[statusTextField setStringValue:message];
}

- (void)setStatus:(id)message withWait:(NSTimeInterval)waitTimeInterval
{
	static NSTimer *statusTimer = nil;
	if (statusTimer)
	{
		[statusTimer invalidate];
		[statusTimer release];
	}
	
	statusTimer = [[NSTimer scheduledTimerWithTimeInterval:waitTimeInterval
													target:self
												  selector:@selector(_setStatus:)
												  userInfo:[message retain]
												   repeats:NO] retain];
}

- (void)setStatus:(id)message
{
	[self setStatus:message withWait:0.3];
}

- (void)joinServer:(MDServer *)server
{
	[modsController setJoiningServer:nil];
	
	// important to check when this action is sent from double clicking in the table
	if ([joinButton isEnabled])
	{
		if (![[MDServer formalizedMapsDictionary] objectForKey:[server map]])
		{
			NSString *mapsDirectory = [[[self applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
			NSString *mapFile = [[server map] stringByAppendingPathExtension:@"map"];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:[mapsDirectory stringByAppendingPathComponent:mapFile]])
			{
				// It's a mod that needs to be downloaded
				[modsController requestModDownload:[server map] andJoinServer:server];
				return;
			}
			
			if ([modsController requestPluginDownloadIfNeededFromMod:[server map] andJoinServer:server])
			{
				// At least one plug-in needs to be downloaded
				return;
			}
		}
		
		if ([server passwordProtected])
		{
			NSDictionary *passwordsDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:HALO_GAMES_PASSWORD_KEY];
			NSString *storedPassword = [passwordsDictionary objectForKey:[server ipAddress]];
			if (storedPassword)
			{
				[serverPasswordTextField setStringValue:storedPassword];
			}
			
			// password prompt
			[NSApp beginSheet:serverPasswordWindow
			   modalForWindow:[self window]
				modalDelegate:self
			   didEndSelector:nil
				  contextInfo:NULL];
		}
		else
		{
			[self connectToServer:server
						 password:@""];
		}
	}
}

- (IBAction)joinGame:(id)sender
{
	[self joinServer:[self selectedServer]];
}

- (void)deinstallGameAndTerminate
{
	NSString *appSupportPath = [self applicationSupportPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:appSupportPath])
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:[appSupportPath stringByDeletingLastPathComponent]
												destination:@""
													  files:[NSArray arrayWithObject:[appSupportPath lastPathComponent]]
														tag:NULL];
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self preferencesPath]])
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:[[self preferencesPath] stringByDeletingLastPathComponent]
												destination:@""
													  files:[NSArray arrayWithObject:[[self preferencesPath] lastPathComponent]]
														tag:NULL];
	}
	
	[NSApp terminate:nil];
}

- (void)abortInstallation:(NSArray *)arguments
{
	NSRunAlertPanel([arguments objectAtIndex:0], [arguments objectAtIndex:1], nil, nil, nil);
	if ([arguments count] > 2)
	{
		[self deinstallGameAndTerminate];
	}
	else
	{
		[NSApp terminate:nil];
	}
}

#define SAVEGAME_DATA_LENGTH 4718592
- (BOOL)writeZeroedSaveGameAtPath:(NSString *)path
{
	return [[NSData dataWithBytesNoCopy:calloc(1, SAVEGAME_DATA_LENGTH) length:SAVEGAME_DATA_LENGTH freeWhenDone:YES] writeToFile:path atomically:YES];
}

- (void)fixDefaultScoreButton
{
	NSString *profileSettingsPath = [self profileSettingsPath];
	if (profileSettingsPath)
	{
		NSMutableData *profileData = [NSMutableData dataWithContentsOfFile:profileSettingsPath];
		if ([profileData length] >= 0x156+2)
		{
			uint16_t oneKeyCode = *(uint16_t *)([profileData bytes] + 0x156);
			if (oneKeyCode == 0x7FFF)
			{
				// Good, the one key isn't in use
				uint16_t functionOneKeyCode = *(uint16_t *)([profileData bytes] + 0x136);
				if (functionOneKeyCode == 0x000C)
				{
					// Good, F1 is being used as score key
					// Have 1 be score key, but keep F1 too so as to not cause confusion
					*(uint16_t *)([profileData mutableBytes] + 0x156) = 0x000C;
					
					[[NSFileManager defaultManager] removeItemAtPath:profileSettingsPath error:nil];
					[profileData writeToFile:profileSettingsPath atomically:YES];
					
					[self fixCRC32ChecksumAtProfilePath:profileSettingsPath];
				}
			}
		}
	}
}

- (NSString *)profileSettingsPath
{
	return [[[[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"HLMD"] stringByAppendingPathComponent:[self architecture]] stringByAppendingPathComponent:@"savegames"] stringByAppendingPathComponent:[self profileName]] stringByAppendingPathComponent:@"blam"] stringByAppendingPathExtension:@"sav"];
}

- (NSString *)architecture
{
	NSString *architecture = nil;
#ifdef __ppc__
	architecture = @"ppc";
#else
	architecture = @"i386";
#endif
	
	return architecture;
}

- (NSString *)profileName
{
	NSString *profileName = nil;
	
	NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString *haloMDDocumentsPath = [documentsPath stringByAppendingPathComponent:@"HLMD"];
	NSString *architectureDirectoryPath = [haloMDDocumentsPath stringByAppendingPathComponent:[self architecture]];
	
	NSString *lastProfilePath = [architectureDirectoryPath stringByAppendingPathComponent:@"lastprof.txt.noindex"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:lastProfilePath])
	{
		NSData *data = [NSData dataWithContentsOfFile:lastProfilePath];
		if (data)
		{
			id profilePathString = [NSMutableString stringWithCString:[data bytes] encoding:NSISOLatin1StringEncoding];
			if (profilePathString && [profilePathString length] > 2)
			{
				[profilePathString deleteCharactersInRange:NSMakeRange(0, 2)]; // remove C:
				[profilePathString replaceOccurrencesOfString:@"\\" withString:@"/" options:NSLiteralSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, [profilePathString length])];
				
				if ([profilePathString length] > 2)
				{
					if ([profilePathString characterAtIndex:[profilePathString length]-1] == '/')
					{
						[profilePathString deleteCharactersInRange:NSMakeRange([profilePathString length]-1, 1)];
					}
					
					profileName = [profilePathString lastPathComponent];
				}
			}
		}
	}
	
	return profileName;
}

- (void)fixCRC32ChecksumAtProfilePath:(NSString *)blamPath
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:blamPath])
	{
		NSTask *fixCRCTask = [[NSTask alloc] init];
		
		@try
		{
			[fixCRCTask setLaunchPath:@"/usr/bin/python"];
			[fixCRCTask setArguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] pathForResource:@"crc32forge" ofType:@"py"], blamPath, nil]];
			[fixCRCTask launch];
			[fixCRCTask waitUntilExit];
			if ([fixCRCTask terminationStatus] != 0)
			{
				NSLog(@"CRC Fix task has failed!");
			}
		}
		@catch (NSException *exception)
		{
			NSLog(@"Fix CRC Task Exception: %@, %@", [exception name], [exception reason]);
		}
		
		[fixCRCTask release];
	}
}

- (IBAction)pickHaloName:(id)sender
{
	NSString *haloName = [[haloNameTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	// 1-11 characters
	if ([haloName length] <= 0 || [haloName length] >= 12)
	{
		NSRunAlertPanel(@"Invalid Halo Name", @"Your Halo name must be 1 to 11 characters long.", nil, nil, nil);
		return;
	}
	
	if ([haloName rangeOfString:@"."].location != NSNotFound)
	{
		NSRunAlertPanel(@"Invalid Halo Name", @"Your Halo name must not contain a period.", nil, nil, nil);
		return;
	}
	
	if ([haloName rangeOfString:@"."].location != NSNotFound || [haloName rangeOfString:@"/"].location != NSNotFound || [haloName rangeOfString:@"\\"].location != NSNotFound || [haloName rangeOfString:@":"].location != NSNotFound)
	{
		NSRunAlertPanel(@"Invalid Halo Name", @"Your Halo name must not contain a period, colon, or slash.", nil, nil, nil);
		return;
	}
	
	if ([haloName isEqualToString:@"checkpoints"] || [haloName isEqualToString:@"saved"])
	{
		NSRunAlertPanel(@"Invalid Halo Name", @"You cannot use this halo name. Please pick another name.", nil, nil, nil);
		return;
	}
	
	if (![haloName dataUsingEncoding:NSISOLatin1StringEncoding])
	{
		NSRunAlertPanel(@"Invalid Halo Name", @"Some of the characters in this halo name cannot be used.", nil, nil, nil);
		return;
	}
	
	NSMutableData *profileData = [NSMutableData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:nil inDirectory:@"Data"]];
	
	unichar *buffer = malloc([haloName length] * sizeof(unichar));
	
	[haloName getCharacters:buffer range:NSMakeRange(0, [haloName length])];
	
	memset([profileData mutableBytes]+0x2, 0, 11*sizeof(unichar));
	memcpy([profileData mutableBytes]+0x2, buffer, [haloName length] * sizeof(unichar));
	
	NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString *haloMDDocumentsPath = [documentsPath stringByAppendingPathComponent:@"HLMD"];
	NSString *architectureDirectoryPath = [haloMDDocumentsPath stringByAppendingPathComponent:[self architecture]];
	NSString *profileDirectoryPath = [[architectureDirectoryPath stringByAppendingPathComponent:@"savegames"] stringByAppendingPathComponent:haloName];
	
	BOOL createdProfileName = YES;
	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:profileDirectoryPath
								   withIntermediateDirectories:YES
													attributes:nil
														 error:NULL])
	{
		createdProfileName = NO;
	}
	else
	{
		if (![self writeZeroedSaveGameAtPath:[profileDirectoryPath stringByAppendingPathComponent:@"savegame.bin"]])
		{
			createdProfileName = NO;
		}
		else
		{
			NSString *blamPath = [profileDirectoryPath stringByAppendingPathComponent:@"blam.sav"];
			if (![profileData writeToFile:blamPath atomically:YES])
			{
				createdProfileName = NO;
			}
			else
			{
				[self fixCRC32ChecksumAtProfilePath:blamPath];
			}
		}
	}
	
	if (!createdProfileName)
	{
		NSRunAlertPanel(@"Failed to create Halo name", @"Your Halo name could not be set. Please set it in-game.", nil, nil, nil);
		NSLog(@"Failed to create profile!");
	}
	else
	{
		NSString *lastProfileUsedPath = [architectureDirectoryPath stringByAppendingPathComponent:@"lastprof.txt.noindex"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:lastProfileUsedPath])
		{
			const int LAST_PROFILE_USED_PATH_LENGTH = 256;
			void *bytes = calloc(1, LAST_PROFILE_USED_PATH_LENGTH);
			
			NSMutableString *profileDirectoryWindowsPath = [[NSMutableString alloc] initWithString:profileDirectoryPath];
			[profileDirectoryWindowsPath replaceOccurrencesOfString:@"/" withString:@"\\" options:NSLiteralSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, [profileDirectoryWindowsPath length])];
			[profileDirectoryWindowsPath insertString:@"C:" atIndex:0];
			
			strncpy(bytes, [profileDirectoryWindowsPath cStringUsingEncoding:NSISOLatin1StringEncoding], LAST_PROFILE_USED_PATH_LENGTH);
			
			[[NSData dataWithBytesNoCopy:bytes length:LAST_PROFILE_USED_PATH_LENGTH freeWhenDone:NO] writeToFile:lastProfileUsedPath atomically:YES];
			
			[profileDirectoryWindowsPath release];
			free(bytes);
		}
	}
	
	free(buffer);
	
	[NSApp endSheet:haloNameWindow];
	[haloNameWindow close];
}

- (IBAction)pickHaloNameRandom:(id)sender
{
	NSString *randomNamesString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"names" ofType:@"txt" inDirectory:@"Data"]
															encoding:NSUTF8StringEncoding
															   error:NULL];
	
	NSArray *randomNames = [randomNamesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	while (YES)
	{
		NSString *pickedName = [randomNames objectAtIndex:rand() % [randomNames count]];
		pickedName = [pickedName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		if ([pickedName length] > 0 && [pickedName length] <= 11)
		{
			[haloNameTextField setStringValue:pickedName];
			break;
		}
	}
}

- (void)pickUserName
{
	// start out with a bang
	[self pickHaloNameRandom:nil];
	
	[NSApp beginSheet:haloNameWindow
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];
}

- (void)updateChangesFrom:(NSString *)haloResourcesPath to:(NSString *)haloLibraryPath
{
	for (NSString *file in [expectedVersionsDictionary allKeys])
	{
		NSString *resourceFile = [[haloResourcesPath stringsByAppendingPaths:[NSArray arrayWithObject:file]] objectAtIndex:0];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:resourceFile])
		{
			NSString *libraryFile = [[haloLibraryPath stringsByAppendingPaths:[NSArray arrayWithObject:file]] objectAtIndex:0];
			
			NSMutableDictionary *currentVersionsDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:HALO_FILE_VERSIONS_KEY]];
			
			NSNumber *oldVersionNumber = [currentVersionsDictionary objectForKey:file];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:libraryFile] || ((!oldVersionNumber || [oldVersionNumber isLessThan:[expectedVersionsDictionary objectForKey:file]]) && ![[NSData dataWithContentsOfFile:libraryFile] isEqualToData:[NSData dataWithContentsOfFile:resourceFile]]))
			{
				[self performSelectorOnMainThread:@selector(requireUserToTerminateHalo) withObject:nil waitUntilDone:YES];
				
				NSString * currentMapIdentifier = nil;
				
				// Trash old library file if it exists, safe and necessary for executable file (so that icon doesn't mess up)
				if ([[NSFileManager defaultManager] fileExistsAtPath:libraryFile])
				{
					if ([[libraryFile lastPathComponent] isEqualToString:@"Halo"] || (![[libraryFile lastPathComponent] isEqualToString:@"bitmaps.map"] && [[libraryFile lastPathComponent] isEqualToString:@"sounds.map"] && [[[libraryFile lastPathComponent] pathExtension] isEqualToString:@"map"]))
					{
						currentMapIdentifier = [modsController readCurrentModIdentifierFromExecutable];
					}
					
					if ([[libraryFile pathExtension] isEqualToString:@"map"])
					{
						// Move to backup file
						NSString *backupPath = [[[libraryFile stringByDeletingPathExtension] stringByAppendingString:@" backup"] stringByAppendingPathExtension:@"map"];
						if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath])
						{
							// Move old backup to trash
							[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
																		 source:[backupPath stringByDeletingLastPathComponent]
																	destination:@""
																		  files:[NSArray arrayWithObject:[backupPath lastPathComponent]]
																			tag:NULL];
						}
						
						[[NSFileManager defaultManager] moveItemAtPath:libraryFile toPath:backupPath error:NULL];
					}
					else
					{
						// Move to trash
						[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
																	 source:[libraryFile stringByDeletingLastPathComponent]
																destination:@""
																	  files:[NSArray arrayWithObject:[libraryFile lastPathComponent]]
																		tag:NULL];
					}
				}
				
				// Copy the new file
				NSError *error = nil;
				if ([[NSFileManager defaultManager] copyItemAtPath:resourceFile toPath:libraryFile error:&error])
				{
					NSLog(@"Overwrote & Updated %@", file);
					[currentVersionsDictionary setObject:[expectedVersionsDictionary objectForKey:file] forKey:file];
					[[NSUserDefaults standardUserDefaults] setObject:currentVersionsDictionary forKey:HALO_FILE_VERSIONS_KEY];
					
					if (currentMapIdentifier)
					{
						[modsController writeCurrentModIdentifier:currentMapIdentifier];
					}
				}
				else
				{
					NSLog(@"Failed to update file Error: %@, %@, %@, %@, %@", file, resourceFile, libraryFile, [error localizedDescription], [error localizedFailureReason]);
					[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Fatal Error", [NSString stringWithFormat:@"HaloMD could not update %@", file], [NSNull null], nil] waitUntilDone:YES];
				}
			}
			else if ([[NSFileManager defaultManager] fileExistsAtPath:libraryFile] && (!oldVersionNumber || [oldVersionNumber isLessThan:[expectedVersionsDictionary objectForKey:file]]) && [[NSData dataWithContentsOfFile:libraryFile] isEqualToData:[NSData dataWithContentsOfFile:resourceFile]])
			{
				NSLog(@"Updating %@ without overwriting", file);
				[currentVersionsDictionary setObject:[expectedVersionsDictionary objectForKey:file] forKey:file];
				[[NSUserDefaults standardUserDefaults] setObject:currentVersionsDictionary forKey:HALO_FILE_VERSIONS_KEY];
			}
		}
	}
}

- (NSString *)serialKey
{
	NSString *serialKey = nil;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self preferencesPath]])
	{
		NSData *preferencesData = [NSData dataWithContentsOfFile:[self preferencesPath]];
		if (preferencesData)
		{
			size_t keyLength = 20;
			const NSUInteger keyOffset = 0xA5;
			
			if ([preferencesData length] >= keyOffset + keyLength)
			{
				void *serialKeyBytes = calloc(1, keyLength);
				[preferencesData getBytes:serialKeyBytes range:NSMakeRange(keyOffset, keyLength)];
				serialKey = [NSString stringWithCString:serialKeyBytes encoding:NSUTF8StringEncoding];
				free(serialKeyBytes);
			}
		}
	}
	
	return serialKey;
}

- (NSString *)randomSerialKey
{
	uint8_t key[10];
	char ascii[20];
	generate_key(key);
	fix_key(key);
	print_key(ascii, key);
	
	return [NSString stringWithCString:ascii encoding:NSUTF8StringEncoding];
}

- (void)installGame
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *appSupportPath = [self applicationSupportPath];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportPath])
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportPath
									   withIntermediateDirectories:NO
														attributes:nil
															 error:NULL])
		{
			NSLog(@"Could not create applicaton support directory: %@", appSupportPath);
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not create the application support folder.", [NSNull null], nil] waitUntilDone:YES];
		}
	}
	
	NSString *gameDataPath = [appSupportPath stringByAppendingPathComponent:@"GameData"];
	NSString *appPath = [appSupportPath stringByAppendingPathComponent:@"HaloMD.app"];
	BOOL gameDataPathExists = [[NSFileManager defaultManager] fileExistsAtPath:gameDataPath];
	BOOL gameAppPathExists = [[NSFileManager defaultManager] fileExistsAtPath:appPath];
	if (!gameDataPathExists || !gameAppPathExists)
	{
		if (gameDataPathExists)
		{
			[[NSFileManager defaultManager] removeItemAtPath:gameDataPath
													   error:NULL];
			gameDataPathExists = NO;
		}
		else if (gameAppPathExists)
		{
			[[NSFileManager defaultManager] removeItemAtPath:appPath
													   error:NULL];
			gameAppPathExists = NO;
		}
	}
	
	NSString *templateInitPath = [gameDataPath stringByAppendingPathComponent:@"template_init.txt"];
	NSString *resourceAppPath = [self resourceAppPath];
	NSString *resourceGameDataPath = [self resourceGameDataPath];
	
	if (!gameDataPathExists && !gameAppPathExists)
	{
		[self setStatusWithoutWait:@"Installing... This may take a few minutes."];
		[installProgressIndicator startAnimation:nil];
		
		if (!resourceGameDataPath)
		{
			NSLog(@"Could not find data path: %@", resourceGameDataPath);
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not find the Data.", nil] waitUntilDone:YES];
		}
		
		NSString *tempGameDataPath = [gameDataPath stringByAppendingString:@"1"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tempGameDataPath])
		{
			[[NSFileManager defaultManager] removeItemAtPath:tempGameDataPath
													   error:NULL];
		}
		
		if (![[NSFileManager defaultManager] copyItemAtPath:resourceGameDataPath
													 toPath:tempGameDataPath
													  error:NULL])
		{
			NSLog(@"Could not copy GameData!");
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not copy Game Data.", [NSNull null], nil] waitUntilDone:YES];
		}
		
		if (![[NSFileManager defaultManager] moveItemAtPath:tempGameDataPath
													 toPath:gameDataPath
													  error:NULL])
		{
			NSLog(@"Could not move game data path!");
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not move Game Data.", [NSNull null], nil] waitUntilDone:YES];
		}
		
		if (!resourceAppPath)
		{
			NSLog(@"Could not find data path: %@", resourceAppPath);
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not find the App Data.", nil] waitUntilDone:YES];
		}
		
		NSString *tempAppPath = [appPath stringByAppendingString:@"1"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tempAppPath])
		{
			[[NSFileManager defaultManager] removeItemAtPath:tempAppPath
													   error:NULL];
		}
		
		if (![[NSFileManager defaultManager] copyItemAtPath:resourceAppPath
													 toPath:tempAppPath
													  error:NULL])
		{
			NSLog(@"Could not copy GameData!");
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not copy Game Data.", [NSNull null], nil] waitUntilDone:YES];
		}
		
		if (![[NSFileManager defaultManager] moveItemAtPath:tempAppPath
													 toPath:appPath
													  error:NULL])
		{
			NSLog(@"Could not move app path!");
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Install Error", @"HaloMD could not move App Data.", [NSNull null], nil] waitUntilDone:YES];
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:[self preferencesPath]])
		{
			[[NSFileManager defaultManager] removeItemAtPath:[self preferencesPath]
													   error:NULL];
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:templateInitPath])
		{
			[[NSFileManager defaultManager] removeItemAtPath:templateInitPath
													   error:NULL];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:expectedVersionsDictionary forKey:HALO_FILE_VERSIONS_KEY];
		
		[installProgressIndicator stopAnimation:nil];
	}
	else
	{
		[self setStatusWithoutWait:@"Applying Updates..."];
		
		NSNumber *bloodgulchVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:HALO_FILE_VERSIONS_KEY] objectForKey:@"Maps/bloodgulch.map"];
		if (bloodgulchVersion && [bloodgulchVersion isLessThan:[NSNumber numberWithInteger:10]])
		{
			// Remove shaft, crossing as infinity, and barrier as boardingaction if it exists from a21 or before
			NSArray *brokenMaps = [NSArray arrayWithObjects:@"putput.map", @"infinity.map", @"boardingaction.map", nil];
			NSString *mapsPath = [gameDataPath stringByAppendingPathComponent:@"Maps"];
			for (NSString *map in brokenMaps)
			{
				if ([[NSFileManager defaultManager] fileExistsAtPath:[mapsPath stringByAppendingPathComponent:map]])
				{
					[self performSelectorOnMainThread:@selector(requireUserToTerminateHalo) withObject:nil waitUntilDone:YES];
					
					NSLog(@"Removing (assuming) broken %@", map);
					[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
																 source:[[mapsPath stringByAppendingPathComponent:map] stringByDeletingLastPathComponent]
															destination:@""
																  files:[NSArray arrayWithObject:map]
																	tag:NULL];
				}
			}
		}
		
		[self updateChangesFrom:resourceAppPath
							 to:appPath];
		
		[self updateChangesFrom:resourceGameDataPath
							 to:gameDataPath];
	}
	
	// Create preferences file if it doesn't exist
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self preferencesPath]])
	{
		NSMutableData *preferencesData = [NSMutableData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:HALO_MD_IDENTIFIER ofType:@"plist"]];
		
		const char *randomKey = [[self randomSerialKey] UTF8String];
		
		[preferencesData replaceBytesInRange:NSMakeRange(0xA5, strlen(randomKey)+1)
								   withBytes:randomKey];
		
		// Obtain graphics card information to decide whether to use vertex shaders only or not
		NSTask *graphicsQueryTask = [[NSTask alloc] init];
		
		[graphicsQueryTask setLaunchPath:@"/usr/sbin/system_profiler"];
		[graphicsQueryTask setArguments:[NSArray arrayWithObjects:@"-xml", @"SPDisplaysDataType", nil]];
		
		NSPipe *pipe = [[NSPipe alloc] init];
		[graphicsQueryTask setStandardOutput:pipe];
		
		NSData *graphicsQueryData = nil;
		
		@try
		{
			[graphicsQueryTask launch];
			graphicsQueryData = [[pipe fileHandleForReading] readDataToEndOfFile];
		}
		@catch (NSException *exception)
		{
			NSLog(@"ERROR: Graphics query task: %@: %@", [exception name], [exception reason]);
		}
		
		[pipe release];
		[graphicsQueryTask release];
		
		BOOL shouldOnlyUseVertexShaders = NO;
		
		@try
		{
			NSArray *properties = [[[[NSString alloc] initWithData:graphicsQueryData encoding:NSUTF8StringEncoding] autorelease] propertyList];
			NSArray *graphicsCardItems = [[properties objectAtIndex:0] objectForKey:@"_items"];
			
			NSString *graphicsCard = [[graphicsCardItems objectAtIndex:0] objectForKey:@"sppci_model"];
			
			// Does the user have an integrated graphics card? http://support.apple.com/kb/HT3246
			if ([graphicsCardItems count] == 1 && ([[NSArray arrayWithObjects:@"GMA 950", @"GMA X3100", @"NVIDIA GeForce 9400M", @"NVIDIA GeForce 320M", nil] containsObject:graphicsCard] || [graphicsCard hasPrefix:@"Intel HD Graphics"]))
			{
				shouldOnlyUseVertexShaders = YES;
			}
		}
		@catch (NSException *exception)
		{
			NSLog(@"ERROR: Failed to obtain graphics card information: %@: %@", [exception name], [exception reason]);
		}
		
		if (shouldOnlyUseVertexShaders)
		{
			char shadersFlag = 1;
			[preferencesData replaceBytesInRange:NSMakeRange(0x44, 1)
									   withBytes:&shadersFlag];
			
			NSLog(@"Using vertex shaders only to avoid graphical glitches since the graphics card is integrated");
		}
		
		if (![preferencesData writeToFile:[self preferencesPath] atomically:YES])
		{
			NSLog(@"Failed to write preferences file!");
			[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Fatal Error", @"HaloMD could not write its preference file.", nil] waitUntilDone:YES];
		}
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:templateInitPath])
	{
		NSString *templateInitString = @"sv_mapcycle_timeout 5";
		if (![templateInitString writeToFile:templateInitPath
								  atomically:YES
									encoding:NSUTF8StringEncoding
									   error:NULL])
		{
			NSLog(@"Failed to write template_init.txt");
		}
	}
	
	if (![[NSFileManager defaultManager] changeCurrentDirectoryPath:[appSupportPath stringByAppendingPathComponent:@"GameData"]])
	{
		NSLog(@"Could not change current directory path to game data");
		[self performSelectorOnMainThread:@selector(abortInstallation:) withObject:[NSArray arrayWithObjects:@"Fatal Error", @"HaloMD could not change its current working directory.", nil] waitUntilDone:YES];
	}
	
	NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString *haloMDDocumentsPath = [documentsPath stringByAppendingPathComponent:@"HLMD"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:haloMDDocumentsPath])
	{
		// Remove all saved campaign games
		NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:haloMDDocumentsPath];
		NSString *filePath;
		NSMutableArray *pathsToRemove = [[NSMutableArray alloc] init];
		NSMutableArray *savebinsToAdd = [[NSMutableArray alloc] init]; // Fixing us not adding this before, argh
		
		BOOL foundProfile = NO;
		
		while (filePath = [directoryEnumerator nextObject])
		{
			NSString *fullFilePath = [haloMDDocumentsPath stringByAppendingPathComponent:filePath];
			
			if ([[filePath lastPathComponent] isEqualToString:@"saved"])
			{
				[directoryEnumerator skipDescendents];
			}
			else if ([[filePath lastPathComponent] isEqualToString:@"savegame.bin"] || [[filePath lastPathComponent] isEqualToString:@"savegame.sav"] || [[filePath lastPathComponent] isEqualToString:@"checkpoints"])
			{
				[pathsToRemove addObject:fullFilePath];
			}
			else if ([[filePath lastPathComponent] isEqualToString:@"blam.sav"])
			{
				foundProfile = YES;
				
				NSString *savegameBinPath = [[fullFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"savegame.bin"];
				if (![[NSFileManager defaultManager] fileExistsAtPath:savegameBinPath])
				{
					[savebinsToAdd addObject:savegameBinPath];
				}
			}
		}
		
		if (!foundProfile)
		{
			[[NSFileManager defaultManager] removeItemAtPath:haloMDDocumentsPath error:NULL];
		}
		else
		{
			for (NSString *filePath in pathsToRemove)
			{
				[[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
				if ([[filePath lastPathComponent] isEqualToString:@"savegame.bin"])
				{
					[self writeZeroedSaveGameAtPath:filePath];
				}
			}
			
			for (NSString *path in savebinsToAdd)
			{
				[self writeZeroedSaveGameAtPath:path];
			}
		}
		
		[savebinsToAdd release];
		[pathsToRemove release];
	}
	
#ifndef __ppc__
	// haven't figured out how checksum works for big endian byte order
	if (![[NSFileManager defaultManager] fileExistsAtPath:haloMDDocumentsPath])
	{
		[self performSelectorOnMainThread:@selector(pickUserName)
							   withObject:nil
							waitUntilDone:YES];
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:HALO_FIX_SCORE_KEY];
	}
#endif
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:haloMDDocumentsPath])
	{
	#ifndef __ppc__
		if (![[NSUserDefaults standardUserDefaults] boolForKey:HALO_FIX_SCORE_KEY])
		{
			[self fixDefaultScoreButton];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:HALO_FIX_SCORE_KEY];
		}
	#endif
	}
	
	isInstalled = YES;
	
	[self setStatusWithoutWait:@""];
	
	[modsController performSelectorOnMainThread:@selector(initiateAndForceDownloadList:) withObject:[NSNumber numberWithBool:shiftKeyHeldDown] waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(refreshServers:) withObject:nil waitUntilDone:YES];
	
	[launchButton setEnabled:YES];
	
	if ([self openFiles])
	{
		[self performSelectorOnMainThread:@selector(addOpenFiles) withObject:nil waitUntilDone:NO];
	}
	
	[pool release];
}

- (void)anotherApplicationDidLaunch:(NSNotification *)notification
{
	if (NSClassFromString(@"NSRunningApplication"))
	{
		NSRunningApplication *runningApplication = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
		if ([haloTask isRunning] && [runningApplication processIdentifier] == [haloTask processIdentifier])
		{
			[runningApplication activateWithOptions:NSApplicationActivateAllWindows];
		}
	}
	else
	{
		if ([haloTask isRunning] && [[[notification userInfo] objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [haloTask processIdentifier])
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[[notification userInfo] objectForKey:@"NSApplicationPath"]]];
		}
	}
}

- (void)anotherApplicationDidTerminate:(NSNotification *)notification
{
	NSString *haloBundleIdentifier = @"com.null.halominidemo";
	if (NSClassFromString(@"NSRunningApplication"))
	{
		NSRunningApplication *runningApplication = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
		if ([runningApplication processIdentifier] == [haloTask processIdentifier] || [[runningApplication bundleIdentifier] isEqualToString:haloBundleIdentifier])
		{
			if ([haloTask isRunning])
			{
				[self terminateHaloInstances];
			}
			[self refreshVisibleServers:nil];
			[self setInGameServer:nil];
		}
	}
	else
	{
		if ([[[notification userInfo] objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [haloTask processIdentifier] || [[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:haloBundleIdentifier])
		{
			if ([haloTask isRunning])
			{
				[self terminateHaloInstances];
			}
			[self refreshVisibleServers:nil];
			[self setInGameServer:nil];
		}
	}
}

- (void)prepareRefreshingForServer:(MDServer *)server
{
	[server setValid:NO];
	[server setLastUpdatedDate:nil];
	[server resetConnectionChances];
	[server setPlayers:nil];
	[inspectorController updateInspectorInformation];
	if (![waitingServersArray containsObject:server])
	{
		[waitingServersArray addObject:server];
	}
}

- (void)refreshVisibleServers:(id)object
{
	if ([[self window] isVisible] && !queryTimer && [serversArray count] > 0 && (![self isHaloOpen] || [[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]))
	{
		NSRange visibleRowsRange = [serversTableView rowsInRect:serversTableView.visibleRect];
		NSArray *servers = [serversArray subarrayWithRange:visibleRowsRange];
		for (MDServer *server in [serversArray subarrayWithRange:visibleRowsRange])
		{
			if (![server outOfConnectionChances])
			{
				[self prepareRefreshingForServer:server];
			}
		}
		
		if ([servers count] > 0)
		{
			[self resumeQueryTimer];
		}
	}
}

- (IBAction)refreshServer:(id)sender
{
	if (queryTimer)
	{
		return;
	}
	
	MDServer *server = [self selectedServer];
	if (server)
	{
		[self prepareRefreshingForServer:server];
	}
	
	[self resumeQueryTimer];
}

- (NSArray *)extraFavoriteServers
{
	NSString *extraFavoritesPath = [[self applicationSupportPath] stringByAppendingPathComponent:@"extra_favorites.txt"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:extraFavoritesPath])
	{
		if (![@"#Add lines in format ip_address:port_number. Start a line as '#' to provide a comment.\n\n" writeToFile:extraFavoritesPath atomically:YES encoding:NSUTF8StringEncoding error:NULL])
		{
			return [NSArray array];
		}
	}
	
	NSData *extraFavoriteServersData = [NSData dataWithContentsOfFile:extraFavoritesPath];
	if (!extraFavoriteServersData)
	{
		return [NSArray array];
	}
	
	NSString *favoritesString = [[NSString alloc] initWithData:extraFavoriteServersData encoding:NSUTF8StringEncoding];
	
	NSMutableArray *extraServerFavorites = [NSMutableArray array];
	
	for (NSString *line in [favoritesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
	{
		NSString *strippedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		if ([strippedLine length] > 0 && ![strippedLine hasPrefix:@"#"] && [[strippedLine componentsSeparatedByString:@":"] count] == 2)
		{
			NSString *host = [MDNetworking addressFromHost:[[strippedLine componentsSeparatedByString:@":"] objectAtIndex:0]];
			NSString *port = [[strippedLine componentsSeparatedByString:@":"] objectAtIndex:1];
			
			NSArray *components = [NSArray arrayWithObjects:host, port, nil];
			[extraServerFavorites addObject:[components componentsJoinedByString:@":"]];
		}
	}
	
	[favoritesString release];
	
	return extraServerFavorites;
}

- (void)handleServerRetrieval:(NSArray *)servers
{
	// Save cache of servers list
	if ([servers count] > 0)
	{
		[[NSUserDefaults standardUserDefaults] setObject:servers forKey:HALO_LOBBY_GAMES_CACHE_KEY];
	}
	
	NSArray *cachedServers = [[NSUserDefaults standardUserDefaults] objectForKey:HALO_LOBBY_GAMES_CACHE_KEY];
	if (!servers && [cachedServers count] > 0)
	{
		servers = cachedServers;
		NSLog(@"Lobby is down, trying to use cache...");
		[self setStatusWithoutWait:@"Connection to lobby failed. Using cache.."];
		self.usingServerCache = YES;
	}
	
	if (servers)
	{
		// it connected
		
		for (NSString *serverString in servers)
		{
			NSArray *serverAndPortArray = [serverString componentsSeparatedByString:@":"];
			if ([serverAndPortArray count] == 2)
			{
				MDServer *server = [[MDServer alloc] init];
				[server setIpAddress:[serverAndPortArray objectAtIndex:0]];
				[server setPortNumber:[[serverAndPortArray objectAtIndex:1] intValue]];
				[waitingServersArray addObject:server];
				[server release];
			}
			else if ([serverAndPortArray count] == 3)
			{
				[self setMyIPAddress:[serverAndPortArray objectAtIndex:0]];
			}
		}
		
		if (isInstalled)
		{
			[self setStatus:nil];
		}
		
		// Start this task
		if (!refreshVisibleServersTimer)
		{
			refreshVisibleServersTimer = [NSTimer scheduledTimerWithTimeInterval:40 target:self selector:@selector(refreshVisibleServers:) userInfo:nil repeats:YES];
		}
		
		[self resumeQueryTimer];
	}
	else if (isInstalled)
	{
		[self setStatus:@"Connection to master server failed."];
	}
}

- (void)grabExtraFavorites:(NSArray	 *)servers
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	if (servers)
	{
		// Attach extra server favorites, make sure to filter out duplicates
		servers = [[NSSet setWithArray:[servers arrayByAddingObjectsFromArray:[self extraFavoriteServers]]] allObjects];
	}
	
	[self performSelectorOnMainThread:@selector(handleServerRetrieval:) withObject:servers waitUntilDone:NO];
	
	[autoreleasePool release];
}

- (void)retrievedServers:(NSArray *)servers
{
	[NSThread detachNewThreadSelector:@selector(grabExtraFavorites:) toTarget:self withObject:servers];
}

- (IBAction)refreshServers:(id)sender
{	
	if (queryTimer)
	{
		return;
	}
	
	self.usingServerCache = NO;
	
	[refreshButton setEnabled:NO];
	[serversArray removeAllObjects];
	[hiddenServersArray removeAllObjects];
	[serversTableView reloadData];
	
	// Offload connecting to lobby on separate thread as several things are capable of blocking the application, something we don't want to happen no matter what..
	[MDNetworking retrieveServers:self];
}

- (void)updateHiddenServers
{
	NSMutableArray *serversToMove = [NSMutableArray array];
	
	for (MDServer *hiddenServer in hiddenServersArray)
	{
		NSString *mapsDirectory = [[[self applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
		NSString *mapFile = [[hiddenServer map] stringByAppendingPathExtension:@"map"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:[mapsDirectory stringByAppendingPathComponent:mapFile]] || [[modsController modListDictionary] objectForKey:[hiddenServer map]])
		{
			[serversToMove addObject:hiddenServer];
		}
	}
	
	for (MDServer *hiddenServer in serversToMove)
	{
		[hiddenServersArray removeObject:hiddenServer];
		[serversArray addObject:hiddenServer];
	}
	
	if ([serversToMove count] > 0)
	{
		[serversTableView reloadData];
	}
}

- (NSString *)gameStringFromCString:(const char *)cString
{
	NSString *gameString = [NSString stringWithCString:cString encoding:NSISOLatin1StringEncoding];
	
	if (!gameString)
	{
		[NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
	}
	
	if (!gameString)
	{
		gameString = [NSString stringWithCString:cString encoding:NSASCIIStringEncoding];
	}
	
	if (!gameString)
	{
		gameString = @"";
	}
	
	return gameString;
}

- (void)resumeQueryTimer
{
	if (!queryTimer)
	{
		queryTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01
													   target:self
													 selector:@selector(queryServers:)
													 userInfo:nil
													  repeats:YES] retain];
		
		[refreshButton setEnabled:NO];
		[serversTableView reloadData];
	}
}

- (void)sortServersArray
{
	[self setServersArray:[NSMutableArray arrayWithArray:[[self serversArray] sortedArrayUsingDescriptors:[serversTableView sortDescriptors]]]];
}

- (BOOL)receiveQuery
{
	NSString *ipAddressRetrieved = nil;
	uint16_t portValueRetrieved = 0;
	NSArray *receivedEntries = [MDNetworking receiveQueryAndGetIPAddress:&ipAddressRetrieved portNumber:&portValueRetrieved];
	if (receivedEntries == nil) return NO;
	
	MDServer *targetServer = nil;
	for (MDServer *server in waitingServersArray)
	{
		if ([server portNumber] == portValueRetrieved && [[server ipAddress] isEqualToString:ipAddressRetrieved])
		{
			targetServer = server;
			break;
		}
	}
	
	if (targetServer == nil) return YES;
	
	if ([receivedEntries count] < 29) return YES;
	
	const char *serverName = [[receivedEntries objectAtIndex:2] bytes];
	const char *maxPlayers = [[receivedEntries objectAtIndex:8] bytes];
	const char *passwordProtected = [[receivedEntries objectAtIndex:10] bytes];
	const char *mapName = [[receivedEntries objectAtIndex:12] bytes];
	const char *numberOfPlayers = [[receivedEntries objectAtIndex:20] bytes];
	const char *variant = [[receivedEntries objectAtIndex:26] bytes];
	const char *gametype = [[receivedEntries objectAtIndex:22] bytes];
	const char *fragLimit = [[receivedEntries objectAtIndex:28] bytes];
	const char *teamPlay = [[receivedEntries objectAtIndex:24] bytes];
	const char *dedicated = [[receivedEntries objectAtIndex:14] bytes];
	
	NSMutableArray *players = [[NSMutableArray alloc] init];
	
	int playerDataIndex = 40;
	int playerIndex;
	for (playerIndex = 0; playerIndex < atoi(numberOfPlayers); playerIndex++)
	{
		if (playerDataIndex+1 >= [receivedEntries count]) break;
		
		const char *playerName = [[receivedEntries objectAtIndex:playerDataIndex] bytes];
		
		playerDataIndex += 1;
		
		const char *playerScore = [[receivedEntries objectAtIndex:playerDataIndex] bytes];
		
		MDPlayer *player = [[MDPlayer alloc] init];
		[player setName:[self gameStringFromCString:playerName]];
		[player setScore:[self gameStringFromCString:playerScore]];
		
		[players addObject:player];
		
		[player release];
		
		playerDataIndex += 3;
	}
	
	[targetServer setPlayers:players];
	
	[players release];
	
	[targetServer setName:[self gameStringFromCString:serverName]];
	[targetServer setMap:[[self gameStringFromCString:mapName] lowercaseString]];
	[targetServer setMaxNumberOfPlayers:atoi(maxPlayers)];
	[targetServer setPasswordProtected:atoi(passwordProtected)];
	[targetServer setCurrentNumberOfPlayers:atoi(numberOfPlayers)];
	[targetServer setGametype:[self gameStringFromCString:gametype]];
	[targetServer resetConnectionChances];
	
	NSString *variantString = [self gameStringFromCString:variant];
	if ([[variantString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
	{
		[targetServer setVariant:[targetServer gametype]];
	}
	else
	{
		[targetServer setVariant:variantString];
	}
	
	[targetServer setTeamPlay:[[self gameStringFromCString:teamPlay] isEqualToString:@"0"] ? @"No" : @"Yes"];
	[targetServer setDedicated:[[self gameStringFromCString:dedicated] isEqualToString:@"0"] ? @"No" : @"Yes"];
	
	NSString *scoreLimit = ([[targetServer gametype] isEqualToString:@"Oddball"] || [[targetServer gametype] isEqualToString:@"King"]) ? [NSString stringWithFormat:@"%s:00", fragLimit] : [NSString stringWithUTF8String:fragLimit];
	[targetServer setScoreLimit:scoreLimit];
	
	double pingDoubleValue = [[NSDate date] timeIntervalSinceDate:[targetServer lastUpdatedDate]];
	int ping = 0;
	if (!isnan(pingDoubleValue))
	{
		ping = (int)(pingDoubleValue * 1000);
	}
	[targetServer setPing:ping];
	
	[targetServer setValid:YES];
	
	if (![serversArray containsObject:targetServer])
	{
		[serversArray addObject:targetServer];
		[self sortServersArray];
	}
	
	NSString *mapsDirectory = [[[self applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
	NSString *mapFile = [[targetServer map] stringByAppendingPathExtension:@"map"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:[mapsDirectory stringByAppendingPathComponent:mapFile]])
	{
		// if it's a full version map or a mod that hasn't be registered on MGM, remove it from the list, but add it as a hidden server
		if ([[MDServer formalizedMapsDictionary] objectForKey:[targetServer map]] || ![[modsController modListDictionary] objectForKey:[targetServer map]])
		{
			[serversArray removeObject:targetServer];
			[hiddenServersArray addObject:targetServer];
		}
	}
	
	[waitingServersArray removeObject:targetServer];
	
	if ([self myIPAddress] && [[targetServer ipAddress] isEqualToString:[self myIPAddress]])
	{
		[self setInGameServer:targetServer	];
	}
	
	if (isInstalled)
	{
		[self setStatus:nil];
	}
	
	[inspectorController updateInspectorInformation];
	
	[serversTableView reloadData];
	
	return YES;
}

- (void)queryServers:(NSTimer *)timer
{
	BOOL serversNeedUpdating = NO;
	
	for (MDServer *server in waitingServersArray)
	{
		if (![server valid] && ![server outOfConnectionChances])
		{
			serversNeedUpdating = YES;
			NSDate *currentDate = [NSDate date];
			if (![server lastUpdatedDate] || [currentDate timeIntervalSinceDate:[server lastUpdatedDate]] >= 0.5)
			{
				[server setLastUpdatedDate:currentDate];
				[MDNetworking queryServerAtAddress:[server ipAddress] port:[server portNumber]];
				
				[server useConnectionChance];
				
				// Keep this in case server is also in serversArray
				if (isInstalled && !self.usingServerCache)
				{
					[self setStatus:nil];
				}
				[serversTableView reloadData];
			}
		}
	}
	
	while ([self receiveQuery])
		;
	
	// Stop when not needed - if it continues running, it consumes CPU resources on the main thread
	if (!serversNeedUpdating)
	{
		for (MDServer *timedOutServer in waitingServersArray)
		{
			if ([[timedOutServer ipAddress] isEqualToString:[self myIPAddress]] && !self.usingServerCache && [self isHaloOpen])
			{
				NSMutableAttributedString *attributedStatus = [[NSMutableAttributedString alloc] initWithString:@"You may be having "];
				[attributedStatus appendAttributedString:[NSAttributedString MDHyperlinkFromString:@"hosting issues." withURL:[NSURL URLWithString:@"http://halomd.net/hosting"]]];
				[self setStatus:attributedStatus];
				[attributedStatus release];
				
				break;
			}
		}
		
		[waitingServersArray removeAllObjects];
		
		[queryTimer invalidate];
		[queryTimer release];
		queryTimer = nil;
		
		[refreshButton setEnabled:YES];
	}
}

- (void)awakeFromNib
{
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
																   ascending:YES
																	selector:@selector(compare:)];
	[serversTableView setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	
	[serversTableView setDoubleAction:@selector(joinGame:)];
	
	// Add a chat button in the window's title bar
	// http://13bold.com/tutorials/accessory-view/
	BOOL supportsFullscreen = ([[self window] collectionBehavior] & NSWindowCollectionBehaviorFullScreenPrimary) != 0;
	NSView *themeFrame = [[[self window] contentView] superview];
	NSRect containerRect = [themeFrame frame];
	NSRect accessoryViewRect = [chatButton frame];
	NSRect newFrame = NSMakeRect(containerRect.size.width - accessoryViewRect.size.width - (supportsFullscreen ? 20 : 0), containerRect.size.height - accessoryViewRect.size.height - 2, accessoryViewRect.size.width, accessoryViewRect.size.height);
		
	[chatButton setFrame:newFrame];
	
	NSImage *icon = [NSImage imageNamed:@"chat_icon.pdf"];
	[icon setTemplate:YES];
	[chatButton setImage:icon];
	
	[themeFrame addSubview:chatButton];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	[modsController openURL:urlString];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows
{
	if (!hasVisibleWindows)
	{
		[[self window] makeKeyAndOrderFront:nil];
	}
	
	return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[chatWindowController cleanup];
	[inspectorController cleanup];
	//[[TCMPortMapper sharedInstance] stopBlocking];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[self window] makeKeyAndOrderFront:nil];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(anotherApplicationDidLaunch:)
															   name:NSWorkspaceDidLaunchApplicationNotification
															 object:nil];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(anotherApplicationDidTerminate:)
															   name:NSWorkspaceDidTerminateApplicationNotification
															 object:nil];
	
	// for CD key generation and name generation
	srand((unsigned)time(NULL));
	
	CGEventRef startupEvent = CGEventCreate(NULL);
	if (CGEventGetFlags(startupEvent) & kCGEventFlagMaskShift)
	{
		shiftKeyHeldDown = YES;
	}
	
	[NSThread detachNewThreadSelector:@selector(installGame)
							 toTarget:self
						   withObject:nil];
	
	[inspectorController initiateGameInspector];
}

- (MDChatWindowController *)chatWindowController
{
	if (!chatWindowController)
	{
		chatWindowController = [[MDChatWindowController alloc] init];
	}
	
	return chatWindowController;
}

- (IBAction)showChatWindow:(id)sender
{
	[[self chatWindowController] showWindow:nil];
}

- (IBAction)showGameFavoritesWindow:(id)sender
{
	if (_favoritesWindowController == nil)
	{
		_favoritesWindowController = [[MDGameFavoritesWindowController alloc] init];
	}
	
	[_favoritesWindowController attachToParentWindow:window andShowFavoritesFromPath:[[self applicationSupportPath] stringByAppendingPathComponent:@"extra_favorites.txt"]];
}

- (IBAction)showLobbyWindow:(id)sender
{
	[[self window] makeKeyAndOrderFront:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [serversArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if (rowIndex >= 0 && (NSUInteger)rowIndex < [serversArray count])
	{
		MDServer *server = [serversArray objectAtIndex:rowIndex];
		
		if ([[tableColumn identifier] isEqualToString:@"name"])
		{
			return [server name];
		}
		else if ([[tableColumn identifier] isEqualToString:@"map"])
		{
			return [server formalizedMap];
		}
		else if ([[tableColumn identifier] isEqualToString:@"players"])
		{
			return ![server valid] ? [server invalidDescription] : [NSString stringWithFormat:@"%d / %d", [server currentNumberOfPlayers], [server maxNumberOfPlayers]];
		}
		else if ([[tableColumn identifier] isEqualToString:@"variant"])
		{
			return ![server valid] ? [server invalidDescription] : [server variant];
		}
		else if ([[tableColumn identifier] isEqualToString:@"password"])
		{
			NSImage *lockImage = ![server valid] ? nil : ([server passwordProtected] ? [NSImage imageNamed:@"lock.png"] : nil);
			[lockImage setTemplate:YES];
			return lockImage;
		}
		else if ([[tableColumn identifier] isEqualToString:@"ping"])
		{
			return ![server valid] ? [server invalidDescription] : ([server ping] == 0 ? @"" : [NSNumber numberWithInt:[server ping]]);
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self sortServersArray];
	[tableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (isInstalled)
	{
		[joinButton setEnabled:[self selectedServer] != nil];
	}
	
	[inspectorController updateInspectorInformation];
}

- (NSString *)tableView:(NSTableView *)tableView
		 toolTipForCell:(NSCell *)cell
				   rect:(NSRectPointer)rect
			tableColumn:(NSTableColumn *)tableColumn
					row:(NSInteger)row
		  mouseLocation:(NSPoint)mouseLocation
{
	NSString *serverDescription = nil;
	
	if (row >= 0 && row < [serversArray count])
	{
		MDServer *server = [serversArray objectAtIndex:row];
		NSArray *playerNames = [[server players] valueForKey:@"name"];
		
		if ([playerNames count] > 0)
		{
			serverDescription = [playerNames componentsJoinedByString:@"\n"];
		}
	}
	
	return serverDescription;
}

@end
