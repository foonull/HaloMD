//
//  MDModsController.h
//  HaloMD
//
//  Created by null on 5/26/12.
//

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
	IBOutlet NSMenu *pluginsMenu;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *refreshButton;
	NSMutableArray *modMenuItems;
	NSMutableDictionary *modListDictionary;
	NSMutableArray *pluginMenuItems;
	
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
@property (nonatomic, retain) NSMutableArray *pluginMenuItems;
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
- (BOOL)addPluginAtPath:(NSString *)filename;

- (NSString *)readCurrentModIdentifierFromExecutable;
- (BOOL)writeCurrentModIdentifier:(NSString *)mapIdentifier;

- (void)requestModDownload:(NSString *)mapIdentifier andJoinServer:(MDServer *)server;
- (void)enableModWithMapIdentifier:(NSString *)mapIdentifier;

- (IBAction)cancelInstallation:(id)sender;
- (IBAction)addMods:(id)sender;

- (IBAction)revealMapsInFinder:(id)sender;

@end
