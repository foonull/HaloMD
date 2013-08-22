//
//  MDModsController.h
//  HaloMD
//
//  Created by null on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCEventListenerProtocol.h"

#define MODS_LIST_DOWNLOAD_TIME_KEY @"MODS_LIST_DOWNLOAD_TIME_KEY"

#define MODDED_SLOT_IDENTIFIER @"gephyrophobia"

@class AppDelegate;
@class MDModPatch;
@class MDServer;

@interface MDModsController : NSObject <SCEventListenerProtocol, NSURLDownloadDelegate>
{
	IBOutlet AppDelegate *appDelegate;
	IBOutlet NSMenu *modsMenu;
	IBOutlet NSMenu *onlineModsMenu;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *refreshButton;
	NSMutableArray *modMenuItems;
	NSMutableDictionary *modListDictionary;
	
	NSURLDownload *modDownload;
	NSString *urlToOpen;
	
	NSString *currentDownloadingMapIdentifier;
	NSString *pendingDownload;
	
	MDModPatch *currentDownloadingPatch;
	
	MDServer *joiningServer;
	
	NSTimer *downloadModListTimer;
	
	NSDate *resumeTimeoutDate;
	
	long long expectedContentLength;
	long long currentContentLength;
	
	BOOL isInitiated;
	BOOL isDownloadingModList;
	BOOL didDownloadModList;
	BOOL isWritingUI;
}

@property (nonatomic, retain) NSMutableArray *modMenuItems;
@property (nonatomic, retain) NSMutableDictionary *modListDictionary;
@property (nonatomic, copy) NSString *currentDownloadingMapIdentifier;
@property (nonatomic, readwrite) BOOL isInitiated;
@property (nonatomic, retain) NSURLDownload *modDownload;
@property (nonatomic, copy) NSString *urlToOpen;
@property (nonatomic, readwrite) BOOL didDownloadModList;
@property (nonatomic, copy) NSString *pendingDownload;
@property (nonatomic, readwrite) BOOL isWritingUI;
@property (nonatomic, retain) MDModPatch *currentDownloadingPatch;
@property (nonatomic, retain) MDServer *joiningServer;

+ (id)modsController;

- (void)openURL:(NSString *)url;

- (void)initiateAndForceDownloadList:(NSNumber *)shouldForceDownloadList;

- (BOOL)addModAtPath:(NSString *)filename;

- (NSString *)readCurrentModIdentifierFromExecutable;
- (BOOL)writeCurrentModIdentifier:(NSString *)mapIdentifier;

- (void)requestModDownload:(NSString *)mapIdentifier andJoinServer:(MDServer *)server;
- (void)enableModWithMapIdentifier:(NSString *)mapIdentifier;

- (IBAction)cancelInstallation:(id)sender;
- (IBAction)addMods:(id)sender;

- (IBAction)revealMapsInFinder:(id)sender;

@end
