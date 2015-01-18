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
//  MDModsController.m
//  HaloMD
//
//  Created by null on 5/26/12.
//

#import "MDModsController.h"
#import "MDModListItem.h"
#import "MDModPatch.h"
#import "MDPluginListItem.h"
#import "MDServer.h"
#import "MDHashDigest.h"
#import <Growl/Growl.h>
#import "AppDelegate.h"
#import "MDHyperLink.h"
#import "SCEvents.h"
#import "SCEvent.h"

#define MAPS_DIRECTORY [[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"]
#define MODS_TEMP_LIST_PATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_mods_list"]

#define MODS_LIST_PATH_WITH_EXTENSION(extension) ([[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"HaloMD_mods_list."extension])

#define MODS_LIST_PATH (gJsonSerializaionExists ? MODS_LIST_PATH_WITH_EXTENSION(@"json") : MODS_LIST_PATH_WITH_EXTENSION(@"plist"))

#define MULTIPLAYER_CODES_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/mods.%@.gz", gJsonSerializaionExists ? @"json" : @"plist"]]

#define MOD_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@.zip", [self currentDownloadingMapIdentifier]]]
#define MOD_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.zip"]

#define MOD_PATCH_DOWNLOAD_URL [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@", [[self currentDownloadingPatch] path]]]
#define MOD_PATCH_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file.mdpatch"]

#define PLUGIN_DOWNLOAD_URL [NSURL URLWithString:[[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/plug-ins/%@.zip", [[self currentDownloadingPlugin] name]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
#define PLUGIN_DOWNLOAD_FILE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_plugin.zip"]

#define PLUGINS_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns"]
#define PLUGINS_DISABLED_DIRECTORY [[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"PlugIns (Disabled)"]

#define BS_PATCH_PATH @"/usr/bin/bspatch"

@implementation MDModsController

@synthesize localModItems;
@synthesize modListDictionary;
@synthesize pluginMenuItems;
@synthesize pluginListDictionary;
@synthesize currentDownloadingMapIdentifier;
@synthesize isInitiated;
@synthesize modDownload;
@synthesize urlToOpen;
@synthesize didDownloadModList;
@synthesize pendingDownload;
@synthesize currentDownloadingPatch;
@synthesize currentDownloadingPlugin;
@synthesize joiningServer;
@synthesize pendingPlugins;

static id sharedInstance = nil;
+ (id)modsController
{
	return sharedInstance;
}

static BOOL gJsonSerializaionExists = NO;
- (id)init
{
	self = [super init];
	if (self)
	{
		sharedInstance = self;
		gJsonSerializaionExists = NSClassFromString(@"NSJSONSerialization") != nil;
	}
	
	return self;
}

- (void)awakeFromNib
{
	[cancelButton setHidden:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)theMenuItem
{
	if ([[pluginsMenu itemArray] containsObject:theMenuItem])
	{
		MDPluginListItem *pluginItem = [theMenuItem representedObject];
		if (pluginItem != nil && [pluginItem isKindOfClass:[MDPluginListItem class]])
		{
			if (pluginItem.enabled)
			{
				[theMenuItem setState:NSOnState];
			}
			else
			{
				[theMenuItem setState:NSOffState];
			}
			
			if ([appDelegate isHaloOpen])
			{
				return NO;
			}
		}
	}
	else if ([theMenuItem action] == @selector(downloadModList:))
	{
		if (![self canDownloadModList])
		{
			return NO;
		}
	}
	
	return YES;
}

- (int)buildNumberFromMapIdentifier:(NSString *)mapIdentifier
{
	int buildNumber = 0;
	
	NSRange range = [mapIdentifier rangeOfString:@"_" options:NSBackwardsSearch];
	if (range.location != NSNotFound)
	{
		if (range.location+1 < [mapIdentifier length])
		{
			buildNumber = [[mapIdentifier substringFromIndex:range.location+1] intValue];
		}
	}
	
	return buildNumber;
}

- (BOOL)isValidBuildNumber:(NSString *)filename
{
	return ([self buildNumberFromMapIdentifier:filename] > 0);
}

- (BOOL)addModAtPath:(NSString *)filename
{
	NSString *errorString = nil;
	NSString *mapIdentifier = nil;
	
	BOOL success = NO;
	
	if (![self isValidBuildNumber:filename])
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its build number is invalid.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: Build number of %@ is invalid", filename);
	}
	else if ([[[filename lastPathComponent] stringByDeletingPathExtension] length] > MAXIMUM_MAP_NAME_LENGTH)
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its filename is too long.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: File name of %@ is too long", filename);
	}
	else if (![[[filename lastPathComponent] stringByDeletingPathExtension] isEqualToString:[[[filename lastPathComponent] stringByDeletingPathExtension] lowercaseString]])
	{
		errorString = [NSString stringWithFormat:@"%@ could not be added because its filename has a capital letter in it.", [[filename lastPathComponent] stringByDeletingPathExtension]];
		NSLog(@"ERROR: File name of %@ is not all lowercase", filename);
	}
	else
	{
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
		if (fileHandle)
		{
			[fileHandle seekToFileOffset:0x20];
			
			NSData *mapNameData = [fileHandle readDataOfLength:MAXIMUM_MAP_NAME_LENGTH+1];
			mapIdentifier = [[NSString alloc] initWithData:mapNameData encoding:NSUTF8StringEncoding];
			
			// Remove ending zeroes
			mapIdentifier = [NSString stringWithCString:[mapIdentifier UTF8String] encoding:NSUTF8StringEncoding];
			
			if (![mapIdentifier isEqualToString:[[filename lastPathComponent] stringByDeletingPathExtension]])
			{
				errorString = [NSString stringWithFormat:@"%@ could not be added because its internal map name is not matching its filename.", [[filename lastPathComponent] stringByDeletingPathExtension]];
				NSLog(@"ERROR: File %@ does not match its internal map name", filename);
				success = NO;
			}
		}
	}
	
	if (!errorString)
	{
		NSString *destination = [MAPS_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
		{
			if (NSRunAlertPanel(@"Mod already exists",
								@"You already have %@. Do you want to replace it?",
								@"Replace", @"Cancel", nil, [filename lastPathComponent]) == NSOKButton)
			{
				[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
															 source:MAPS_DIRECTORY
														destination:@""
															  files:[NSArray arrayWithObject:[destination lastPathComponent]]
																tag:NULL];
			}
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
		{
			[[NSFileManager defaultManager] moveItemAtPath:filename
													toPath:destination
													 error:nil];
			
			success = YES;
		}
	}
	else
	{
		NSRunAlertPanel(@"Failed Adding Mod",
						@"%@",
						@"OK", nil, nil, errorString);
	}
	
	return success;
}

- (BOOL)addPluginAtPath:(NSString *)filename preferringEnabledState:(BOOL)preferringEnabledState
{
	if ([NSBundle bundleWithPath:filename] == nil)
	{
		NSLog(@"%@ is not a valid plugin bundle", filename);
		NSRunAlertPanel(@"Failed Adding Extension",
						@"%@ is not a valid extension",
						@"OK", nil, nil, [[filename lastPathComponent] stringByDeletingPathExtension]);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY])
	{
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DIRECTORY withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Failed to create PlugIns directory: %@", error);
			return NO;
		}
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY])
	{
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DISABLED_DIRECTORY withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Failed to create PlugIns disabled directory: %@", error);
			return NO;
		}
	}
	
	NSString *enabledPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	BOOL existedAtEnabledPath = [[NSFileManager defaultManager] fileExistsAtPath:enabledPath];
	if (existedAtEnabledPath)
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:[filename lastPathComponent]];
	BOOL existedAtDisabledPath = [[NSFileManager defaultManager] fileExistsAtPath:disabledPath];
	if (existedAtDisabledPath)
	{
		[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
													 source:PLUGINS_DISABLED_DIRECTORY
												destination:@""
													  files:[NSArray arrayWithObject:[filename lastPathComponent]]
														tag:0];
	}
	
	NSString *destination = nil;
	if (existedAtDisabledPath)
	{
		destination = disabledPath;
	}
	else if (existedAtEnabledPath)
	{
		destination = enabledPath;
	}
	else if (preferringEnabledState)
	{
		destination = enabledPath;
	}
	else
	{
		destination = disabledPath;
	}
	
	NSError *error = nil;
	if (![[NSFileManager defaultManager] moveItemAtPath:filename toPath:destination error:&error])
	{
		NSLog(@"Error moving plugin: %@", error);
		NSRunAlertPanel(@"Failed Adding Extension",
						@"%@ could not be moved into PlugIns",
						@"OK", nil, nil, [[filename lastPathComponent] stringByDeletingPathExtension]);
		return NO;
	}
	
	return YES;
}

- (IBAction)addMods:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Add Mods"];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setPrompt:@"Add"];
	
	[openPanel beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSOKButton)
		{
			for (NSURL *url in [openPanel URLs])
			{
				[self addModAtPath:@([url fileSystemRepresentation])];
			}
		}
	}];
}

- (NSArray *)mapsToIgnore
{
	return @[@"bloodgulch", @"barrier", @"crossing", @"beavercreek", @"bitmaps", @"boardingaction", @"carousel", @"chillout", @"damnation", @"dangercanyon", @"deathisland", @"hangemhigh", @"icefields", @"infinity", @"longest", @"prisoner", @"putput", @"ratrace", @"sidewinder", @"sounds", @"timberland", @"ui", @"wizard", @"a10", @"a30", @"a50", @"b30", @"b40", @"c10", @"c20", @"c40", @"d20", @"d40"];
}

- (void)makeModMenuItems
{
	if ([self localModItems] == nil)
	{
		[self setLocalModItems:[NSMutableArray array]];
	}
	else
	{
		[[self localModItems] removeAllObjects];
	}
	
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:MAPS_DIRECTORY];
	NSString *file = nil;
	
	[directoryEnumerator skipDescendents];
	
	NSArray *ignoredMaps = [self mapsToIgnore];

	while (file = [directoryEnumerator nextObject])
	{
		if ([[file pathExtension] isEqualToString:@"map"] && ![ignoredMaps containsObject:[file stringByDeletingPathExtension]])
		{
			MDModListItem *listItem = [[MDModListItem alloc] init];
			[listItem setIdentifier:[file stringByDeletingPathExtension]];
			
			[listItem setName:[listItem identifier]];
			BOOL validBuildNumber = [self isValidBuildNumber:[listItem identifier]];
			
			if (validBuildNumber)
			{
				NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[MAPS_DIRECTORY stringByAppendingPathComponent:file]];
				if (fileHandle)
				{
					[fileHandle seekToFileOffset:0x20];
					
					NSData *mapNameData = [fileHandle readDataOfLength:MAXIMUM_MAP_NAME_LENGTH+1];
					NSString *mapIdentifier = [[NSString alloc] initWithData:mapNameData encoding:NSUTF8StringEncoding];
					
					// Remove ending zeroes
					mapIdentifier = [NSString stringWithCString:[mapIdentifier UTF8String] encoding:NSUTF8StringEncoding];
					
					if ([mapIdentifier isEqualToString:[listItem identifier]])
					{
						[[self localModItems] addObject:listItem];
					}
				}
			}
		}
	}
}

- (void)enablePlugin:(NSMenuItem *)menuItem
{
	MDPluginListItem *pluginItem = [menuItem representedObject];
	NSString *normalPath = [PLUGINS_DIRECTORY stringByAppendingPathComponent:[pluginItem.name stringByAppendingPathExtension:@"mdplugin"]];
	NSString *disabledPath = [PLUGINS_DISABLED_DIRECTORY stringByAppendingPathComponent:[pluginItem.name stringByAppendingPathExtension:@"mdplugin"]];
	
	if (pluginItem.enabled)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY] && ![[NSFileManager defaultManager] fileExistsAtPath:disabledPath])
		{
			if ([[NSFileManager defaultManager] moveItemAtPath:normalPath toPath:disabledPath error:NULL])
			{
				pluginItem.enabled = NO;
			}
		}
	}
	else
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY] && ![[NSFileManager defaultManager] fileExistsAtPath:normalPath])
		{
			if ([[NSFileManager defaultManager] moveItemAtPath:disabledPath toPath:normalPath error:NULL])
			{
				pluginItem.enabled = YES;
			}
		}
	}
}

// Prevent infoDictionary bundle caching if possible
- (NSDictionary *)infoDictionaryFromBundle:(NSBundle *)bundle
{
	NSString *infoPath = [[[bundle bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath])
	{
		return [NSDictionary dictionaryWithContentsOfFile:infoPath];
	}
	return [bundle infoDictionary];
}

- (void)addPluginsFromDirectory:(NSString *)directory intoArray:(NSMutableArray *)pluginItems enabled:(BOOL)enabled
{
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
	
	for (NSString *file in directoryEnumerator)
	{
		if ([[file pathExtension] isEqualToString:@"mdplugin"])
		{
			NSBundle *pluginBundle = [NSBundle bundleWithPath:[directory stringByAppendingPathComponent:file]];
			if (pluginBundle != nil)
			{
				NSDictionary *infoDictionary = [self infoDictionaryFromBundle:pluginBundle];
				NSNumber *globalPluginValue = [infoDictionary objectForKey:@"MDGlobalPlugin"];
				NSNumber *mapPluginValue = [infoDictionary objectForKey:@"MDMapPlugin"];
				NSUInteger buildNumber = [[infoDictionary objectForKey:@"CFBundleVersion"] integerValue];
				if (buildNumber > 0 && ([globalPluginValue boolValue] || [mapPluginValue boolValue]))
				{
					MDPluginListItem *pluginItem = [[MDPluginListItem alloc] init];
					
					pluginItem.enabled = enabled;
					pluginItem.globalMode = [globalPluginValue boolValue];
					pluginItem.mapMode = [mapPluginValue boolValue];
					
					pluginItem.name = [file stringByDeletingPathExtension];
					pluginItem.build = buildNumber;
					pluginItem.version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
					
					[pluginItems addObject:pluginItem];
				}
			}
		}
		
		[directoryEnumerator skipDescendents];
	}
}

- (void)makePluginMenuItems
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DIRECTORY])
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DIRECTORY withIntermediateDirectories:NO attributes:nil error:NULL])
		{
			NSLog(@"Failed to create %@", PLUGINS_DIRECTORY);
			return;
		}
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:PLUGINS_DISABLED_DIRECTORY])
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:PLUGINS_DISABLED_DIRECTORY withIntermediateDirectories:NO attributes:nil error:NULL])
		{
			NSLog(@"Failed to create %@", PLUGINS_DISABLED_DIRECTORY);
			return;
		}
	}
	
	if ([self pluginMenuItems] == nil)
	{
		[self setPluginMenuItems:[NSMutableArray array]];
	}
	else
	{
		for (id menuItem in [self pluginMenuItems])
		{
			if ([[menuItem representedObject] globalMode])
			{
				[pluginsMenu removeItem:menuItem];
			}
		}
		
		[[self pluginMenuItems] removeAllObjects];
		
		if ([[[pluginsMenu itemArray] lastObject] action] == @selector(doNothing:))
		{
			[pluginsMenu removeItem:[[pluginsMenu itemArray] lastObject]];
		}
	}
	
	NSMutableArray *newPluginItems = [NSMutableArray array];
	[self addPluginsFromDirectory:PLUGINS_DIRECTORY intoArray:newPluginItems enabled:YES];
	[self addPluginsFromDirectory:PLUGINS_DISABLED_DIRECTORY intoArray:newPluginItems enabled:NO];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	NSArray *sortedItems = [newPluginItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	BOOL addedPlugins = NO;
	if (sortedItems.count > 0)
	{
		for (MDPluginListItem *pluginItem in newPluginItems)
		{
			NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:pluginItem.name action:@selector(enablePlugin:) keyEquivalent:@""];
			newMenuItem.representedObject = pluginItem;
			newMenuItem.target = self;
			
			if (pluginItem.globalMode)
			{
				[pluginsMenu addItem:newMenuItem];
				addedPlugins = YES;
			}
			
			[[self pluginMenuItems] addObject:newMenuItem];
		}
	}
	
	if (!addedPlugins)
	{
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No Available Extensions" action:@selector(doNothing:) keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[pluginsMenu addItem:menuItem];
	}
}

- (BOOL)reportWhatIsInstalling
{
	BOOL hadToReport = NO;
	
	if ([self currentDownloadingMapIdentifier] != nil)
	{
		NSRunAlertPanel(@"Installation in Progress",
						@"You are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
		hadToReport = YES;
	}
	else if ([self currentDownloadingPlugin] != nil)
	{
		NSRunAlertPanel(@"Installation in Progress",
						@"You are currently installing %@. Please try again when the installation finishes.",
						@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
		hadToReport = YES;
	}
	
	return hadToReport;
}

- (void)installOnlineModWithIdentifier:(NSString *)identifier
{
	if (![self reportWhatIsInstalling])
	{
		[self downloadMod:identifier];
	}
}

- (void)installOnlineMod:(id)sender
{
	MDModListItem *listItem = [sender representedObject];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *mapPath = [MAPS_DIRECTORY stringByAppendingPathComponent:[[listItem identifier] stringByAppendingPathExtension:@"map"]];

	if (![fileManager fileExistsAtPath:mapPath] || [[listItem plugins] count] > 0 || [listItem md5Hash] == nil || ![[self md5HashFromFilePath:mapPath] isEqualToString:[listItem md5Hash]])
	{
		[self installOnlineModWithIdentifier:[listItem identifier]];
	}
	else
	{
		[[NSWorkspace sharedWorkspace] selectFile:mapPath inFileViewerRootedAtPath:MAPS_DIRECTORY];
	}
}

- (void)installOnlinePlugin:(MDPluginListItem *)plugin
{
	if (![self reportWhatIsInstalling])
	{
		[self downloadPlugin:plugin];
	}
}

- (void)installPluginsWithNames:(NSArray *)pluginNamesToInstall
{
	NSMutableArray *plugins = [NSMutableArray array];
	for (NSString *pluginName in pluginNamesToInstall)
	{
		MDPluginListItem *plugin = [pluginListDictionary objectForKey:pluginName];
		if (plugin != nil)
		{
			[plugins addObject:plugin];
		}
	}
	
	if (plugins.count > 0)
	{
		[self setPendingPlugins:plugins];
		[self downloadPlugin:[plugins objectAtIndex:0]];
	}
}

- (void)installPlugin:(id)sender
{
	[self installOnlinePlugin:[sender representedObject]];
}

- (void)removeAllItemsFromMenu:(NSMenu *)menu
{
	if ([menu respondsToSelector:@selector(removeAllItems)])
	{
		[menu removeAllItems];
	}
	else
	{
		while ([[menu itemArray] count] > 0)
		{
			[menu removeItemAtIndex:0];
		}
	}
}

- (NSDictionary *)dictionaryFromPath:(NSString *)path
{
	NSDictionary *dictionary = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		if ([[path pathExtension] isEqualToString:@"plist"])
		{
			dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
		}
		else if ([[path pathExtension] isEqualToString:@"json"] && gJsonSerializaionExists)
		{
			NSData *jsonData = [NSData dataWithContentsOfFile:path];
			if (jsonData != nil)
			{
				NSError *error = nil;
				dictionary = [NSClassFromString(@"NSJSONSerialization") JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
				if (error != nil)
				{
					NSLog(@"Error decoding JSON: %@", error);
				}
			}
		}
	}
	return dictionary;
}

- (void)updateOnlineModStates
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];

	for (NSMenuItem *menuItem in [onlineModsMenu itemArray])
	{
		MDModListItem *listItem = [menuItem representedObject];
		if ([listItem isKindOfClass:[MDModListItem class]])
		{
			[menuItem setState:[fileManager fileExistsAtPath:[MAPS_DIRECTORY stringByAppendingPathComponent:[[listItem identifier] stringByAppendingPathExtension:@"map"]]] ? NSOnState : NSOffState];
		}
	}
}

- (void)makeModsList
{
	NSDictionary *modsDictionary = [[self dictionaryFromPath:MODS_LIST_PATH] objectForKey:@"Mods"];
	if (modsDictionary == nil)
	{
		NSLog(@"Mods: Failed to load %@", MODS_LIST_PATH);
	}
	else
	{
		// Remove blank separator and refresh list options..
		NSMutableArray *onlineItemsToRemove = [NSMutableArray array];
		for (id item in [onlineModsMenu itemArray])
		{
			if (![item representedObject])
			{
				[onlineItemsToRemove addObject:item];
			}
		}
		
		for (id item in onlineItemsToRemove)
		{
			[onlineModsMenu removeItem:item];
		}
		
		[self setModListDictionary:[NSMutableDictionary dictionary]];
		
		for (NSDictionary *modDictionary in modsDictionary)
		{
			MDModListItem *listItem = [[MDModListItem alloc] init];
			
			[listItem setIdentifier:[modDictionary objectForKey:@"identifier"]];
			[listItem setVersion:[modDictionary objectForKey:@"human_version"]];
			[listItem setName:[modDictionary objectForKey:@"name"]];
			[listItem setDescription:[modDictionary objectForKey:@"description"]];
			[listItem setMd5Hash:[modDictionary objectForKey:@"hash"]];
			
			NSMutableArray *patches = [NSMutableArray array];
			for (NSDictionary *patchDictionary in [modDictionary objectForKey:@"patches"])
			{
				MDModPatch *newPatch = [[MDModPatch alloc] init];
				[newPatch setBaseIdentifier:[patchDictionary objectForKey:@"base_identifier"]];
				[newPatch setBaseHash:[patchDictionary objectForKey:@"base_hash"]];
				[newPatch setPath:[patchDictionary objectForKey:@"path"]];
				[patches addObject:newPatch];
			}
			
			[listItem setPatches:patches];
			NSArray *plugins = [modDictionary objectForKey:@"plug-ins"];
			if (plugins == nil)
			{
				plugins = [NSArray array];
			}
			[listItem setPlugins:plugins];
			
			if ([listItem name])
			{
				NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[listItem name] action:@selector(installOnlineMod:) keyEquivalent:@""];
				[menuItem setTarget:self];
				[menuItem setRepresentedObject:listItem];
				[menuItem setToolTip:[listItem description]];
				
				NSMenuItem *previousItem = [onlineModsMenu itemWithTitle:[listItem name]];
				if (previousItem)
				{
					int previousBuildNumber = [self buildNumberFromMapIdentifier:[[previousItem representedObject] identifier]];
					int currentBuildNumber = [self buildNumberFromMapIdentifier:[[menuItem representedObject] identifier]];
					
					if (currentBuildNumber > previousBuildNumber)
					{
						[onlineModsMenu removeItem:previousItem];
						[onlineModsMenu addItem:menuItem];
					}
				}
				else
				{
					[onlineModsMenu addItem:menuItem];
				}
				
				[[self modListDictionary] setObject:listItem forKey:[listItem identifier]];
			}
		}
		
		// Sort the online menu items
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
		NSArray *sortedMenuItems = [[onlineModsMenu itemArray] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		[self removeAllItemsFromMenu:onlineModsMenu];
		for (id item in sortedMenuItems)
		{
			[onlineModsMenu addItem:item];
		}
		
		// Add refresh list and blank separator options
		NSMenuItem *refreshDownloadListMenuItem = [[NSMenuItem alloc] initWithTitle:@"Refresh List" action:@selector(downloadModList:) keyEquivalent:@"r"];
		[refreshDownloadListMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		[refreshDownloadListMenuItem setTarget:self];
		[onlineModsMenu addItem:[NSMenuItem separatorItem]];
		[onlineModsMenu addItem:refreshDownloadListMenuItem];
		
		[self updateOnlineModStates];

		[appDelegate updateHiddenServers];
	}
}

- (void)makePluginsList
{
	NSDictionary *pluginsDictionary = [[self dictionaryFromPath:MODS_LIST_PATH] objectForKey:@"Plug-ins"];
	[self setPluginListDictionary:[NSMutableDictionary dictionary]];
	
	if (pluginsDictionary == nil)
	{
		NSLog(@"Failed to find Plug-ins key in %@", MODS_LIST_PATH);
		[self removeAllItemsFromMenu:onlinePluginsMenu];
	}
	else
	{
		[self removeAllItemsFromMenu:onlinePluginsMenu];
		
		NSMutableArray *pluginItems = [NSMutableArray array];
		
		for (NSDictionary *pluginDictionary in pluginsDictionary)
		{
			NSString *name = [pluginDictionary objectForKey:@"name"];
			NSString *description = [pluginDictionary objectForKey:@"description"];
			NSUInteger buildNumber = [[pluginDictionary objectForKey:@"build"] integerValue];
			NSString *version = [pluginDictionary objectForKey:@"version"];
			BOOL globalMode = [[pluginDictionary objectForKey:@"MDGlobalPlugin"] boolValue];
			BOOL mapMode = [[pluginDictionary objectForKey:@"MDMapPlugin"] boolValue];
			
			MDPluginListItem *newItem = [[MDPluginListItem alloc] init];
			newItem.name = name;
			newItem.description = description;
			newItem.build = buildNumber;
			newItem.version = version;
			newItem.mapMode = mapMode;
			newItem.globalMode = globalMode;
			
			if (newItem.globalMode)
			{
				[pluginItems addObject:newItem];
			}
			
			if (newItem.globalMode || newItem.mapMode)
			{
				[pluginListDictionary setObject:newItem forKey:name];
			}
		}
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
		NSArray *sortedPlugins = [pluginItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		for (MDPluginListItem *plugin in sortedPlugins)
		{
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:plugin.name action:@selector(installPlugin:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setToolTip:plugin.description];
			[menuItem setRepresentedObject:plugin];
			
			[onlinePluginsMenu addItem:menuItem];
		}
	}
	
	for (NSMenuItem *menuItem in [self pluginMenuItems])
	{
		MDPluginListItem *plugin = [menuItem representedObject];
		MDPluginListItem *onlinePlugin = [pluginListDictionary objectForKey:plugin.name];
		if (plugin == nil || onlinePlugin == nil || !plugin.globalMode)
		{
			continue;
		}
		
		if (onlinePlugin.description != nil)
		{
			plugin.description = onlinePlugin.description;
			[menuItem setToolTip:plugin.description];
		}
	}
}

- (BOOL)showModUpdateNoticeIfNeeded
{
	NSMutableArray *itemsToUpdate = [NSMutableArray array];
	
	for (MDModListItem *modItem in [self localModItems])
	{
		NSString *modName = [[[self modListDictionary] objectForKey:modItem.identifier] name];
		if (modName == nil) continue;
		
		MDModListItem *onlineItem = nil;
		for (NSMenuItem *onlineMenuItem in [onlineModsMenu itemArray])
		{
			MDModListItem *onlineModItem = [onlineMenuItem representedObject];
			if (onlineModItem != nil && [[onlineModItem name] isEqualToString:modName])
			{
				onlineItem = onlineModItem;
				break;
			}
		}
		
		if (onlineItem != nil && ![[self localModItems] containsObject:onlineItem] && [self buildNumberFromMapIdentifier:[onlineItem identifier]] > [self buildNumberFromMapIdentifier:[modItem identifier]])
		{
			[itemsToUpdate addObject:onlineItem];
		}
	}
	
	if ([itemsToUpdate count] > 0)
	{
		MDModListItem *randomItem = [itemsToUpdate objectAtIndex:rand() % [itemsToUpdate count]];
		
		NSAttributedString *statusString =  [NSAttributedString MDHyperlinkFromString:[NSString stringWithFormat:@"Update %@", [randomItem name]] withURL:[NSURL URLWithString:[NSString stringWithFormat:@"halomdinstall://%@", [randomItem identifier]]]];
		
		[appDelegate setStatus:statusString];
	}
	
	return [itemsToUpdate count] > 0;
}

- (void)showPluginUpdateNoticeIfNeeded
{
	NSMutableArray *favorableItemsToUpdate = [NSMutableArray array];
	
	NSMutableArray *otherItemsToUpdate = [NSMutableArray array];
	NSMutableArray *otherMapNamesToUpdate = [NSMutableArray array];
	
	for (NSMenuItem *menuItem in [self pluginMenuItems])
	{
		MDPluginListItem *pluginItem = [menuItem representedObject];
		MDPluginListItem *onlinePluginItem = [pluginListDictionary objectForKey:[pluginItem name]];
		if (pluginItem == nil || onlinePluginItem == nil)
		{
			continue;
		}
		
		if (pluginItem.build < onlinePluginItem.build)
		{
			if (pluginItem.globalMode && pluginItem.enabled)
			{
				[favorableItemsToUpdate addObject:pluginItem];
			}
			else if (favorableItemsToUpdate.count == 0)
			{
				NSString *mapCandidate = nil;
				for (MDModListItem *modItem in [self localModItems])
				{
					NSArray *plugins = [[[self modListDictionary] objectForKey:modItem.identifier] plugins];
					if ([plugins containsObject:pluginItem.name])
					{
						mapCandidate = [modItem name];
						break;
					}
				}
				
				if (mapCandidate != nil)
				{
					[otherItemsToUpdate addObject:pluginItem];
					[otherMapNamesToUpdate addObject:mapCandidate];
				}
			}
		}
	}
	
	MDPluginListItem *randomItem = nil;
	NSString *randomName = nil;
	NSUInteger randomIndex = 0;
	if ([favorableItemsToUpdate count] > 0)
	{
		randomIndex = rand() % [favorableItemsToUpdate count];
		randomItem = [favorableItemsToUpdate objectAtIndex:randomIndex];
		randomName = randomItem.name;
	}
	else if ([otherItemsToUpdate count] > 0)
	{
		randomIndex = rand() % [otherItemsToUpdate count];
		randomItem = [otherItemsToUpdate objectAtIndex:randomIndex];
		randomName = [otherMapNamesToUpdate objectAtIndex:randomIndex];
	}
	
	if (randomItem != nil)
	{
		NSAttributedString *statusString =  [NSAttributedString MDHyperlinkFromString:[NSString stringWithFormat:@"Update %@", randomName] withURL:[NSURL URLWithString:[[NSString stringWithFormat:@"halomdplugininstall://%@", [randomItem name]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		
		[appDelegate setStatus:statusString];
	}
}

- (void)showUpdateNoticeIfNeeded
{
	if ([appDelegate isQueryingServers] || [self currentDownloadingMapIdentifier] || [self currentDownloadingPlugin])
	{
		[self performSelector:@selector(showUpdateNoticeIfNeeded) withObject:nil afterDelay:10.0];
		return;
	}
	
	if (![self showModUpdateNoticeIfNeeded])
	{
		[self showPluginUpdateNoticeIfNeeded];
	}
}

- (void)stopAndStartDownloadModListTimer
{
	// Check download list every 30 minutes
	[downloadModListTimer invalidate];
	downloadModListTimer = [NSTimer scheduledTimerWithTimeInterval:60*30 target:self selector:@selector(downloadModList) userInfo:nil repeats:YES];
}

- (IBAction)downloadModList:(id)sender
{
	[self downloadModList];
}

- (BOOL)canDownloadModList
{
	return (!isDownloadingModList && ![appDelegate isHaloOpen]);
}

- (void)downloadModList
{
	if ([self canDownloadModList])
	{
		NSURLRequest *request = [NSURLRequest requestWithURL:MULTIPLAYER_CODES_URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
		NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
		
		[download setDestination:MODS_TEMP_LIST_PATH allowOverwrite:YES];
		isDownloadingModList = YES;
		
		[self stopAndStartDownloadModListTimer];
	}
}

- (NSString *)directoryNameFromRequest:(NSURLRequest *)request
{
	return [[[[request URL] absoluteString] stringByDeletingLastPathComponent] lastPathComponent];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	if ([[[download request] URL] isEqual:MULTIPLAYER_CODES_URL])
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:MODS_LIST_PATH])
		{
			[[NSFileManager defaultManager] removeItemAtPath:MODS_LIST_PATH error:nil];
		}
		
		[[NSFileManager defaultManager] moveItemAtPath:MODS_TEMP_LIST_PATH
												toPath:MODS_LIST_PATH
												 error:nil];
		
		[self makeModsList];
		[self makePluginsList];
		[self setDidDownloadModList:YES];
		isDownloadingModList = NO;
		if ([self pendingDownload])
		{
			NSLog(@"Re-trying to download %@", [self pendingDownload]);
			[self downloadMod:[self pendingDownload]];
			[self setPendingDownload:nil];
		}
		[self performSelector:@selector(showUpdateNoticeIfNeeded) withObject:nil afterDelay:10.0];
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"])
	{
		NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Unzip"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
		{
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		BOOL addedMod = NO;
		
		if ([[NSFileManager defaultManager] createDirectoryAtPath:unzipDirectory withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSTask *unzipTask = [[NSTask alloc] init];
			
			[unzipTask setLaunchPath:@"/usr/bin/unzip"];
			[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", @"-q", @"-d", unzipDirectory, MOD_DOWNLOAD_FILE, nil]];
			
			BOOL didUnzip = YES;
			
			@try
			{
				[unzipTask launch];
				[unzipTask waitUntilExit];
			}
			@catch (NSException *exception)
			{
				NSLog(@"Failed unzipping: %@, %@", [exception name], [exception reason]);
				didUnzip = NO;
			}
			
			if (didUnzip)
			{
				NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:unzipDirectory];
				NSString *file = nil;
				while (file = [directoryEnumerator nextObject])
				{
					if ([[file pathExtension] isEqualToString:@"map"] && ![[self mapsToIgnore] containsObject:[[file lastPathComponent] stringByDeletingPathExtension]] && ![[file lastPathComponent] hasPrefix:@"."])
					{
						if ([self pendingPlugins] == nil && (![[appDelegate window] isKeyWindow] || ![NSApp isActive]))
						{
							[NSClassFromString(@"GrowlApplicationBridge")
							 notifyWithTitle:@"Download Finished"
							 description:[NSString stringWithFormat:@"You can now play %@", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]]
							 notificationName:@"ModDownloaded"
							 iconData:nil
							 priority:0
							 isSticky:NO
							 clickContext:@"ModDownloaded"];
						}
						
						addedMod = [self addModAtPath:[unzipDirectory stringByAppendingPathComponent:file]];
					}
				}
			}
			else
			{
				NSRunAlertPanel(@"Mod Installation Failed",
								@"%@ failed to install. Perhaps the downloaded file was corrupted.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		else
		{
			NSRunAlertPanel(@"Mod Installation Failed",
							@"%@ failed to install. HaloMD could not create a temporary directory for installation.",
							@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
		}
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		NSArray *plugins = [self pluginsNotInstalledFromPluginNames:[[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] plugins]];
		[self setCurrentDownloadingMapIdentifier:nil];
		if (plugins.count > 0)
		{
			[self installPluginsWithNames:plugins];
		}
		
		if (!addedMod)
		{
			[self setJoiningServer:nil];
		}
		else
		{
			[self updateOnlineModStates];
			
			if ([self pendingPlugins] == nil)
			{
				if ([[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
				{
					[appDelegate joinServer:[self joiningServer]	];
				}
				[self setJoiningServer:nil];
			}
		}
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"patches"])
	{
		NSString *baseMapPath = [self originalMapPathFromIdentifier:[[self currentDownloadingPatch] baseIdentifier]];
		
		BOOL addedMod = NO;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:baseMapPath])
		{
			NSLog(@"ERROR: Failed to find base map: %@", baseMapPath);
			NSRunAlertPanel(@"Mod Installation Failed",
							@"%@ failed to install because %@ could not be found.",
							@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name], [[self currentDownloadingPatch] baseIdentifier]);
		}
		else
		{
			NSString *newMapPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[self currentDownloadingMapIdentifier] stringByAppendingPathExtension:@"map"]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:newMapPath])
			{
				[[NSFileManager defaultManager] removeItemAtPath:newMapPath error:nil];
			}
			
			NSTask *patchTask = [[NSTask alloc] init];
			
			[patchTask setLaunchPath:BS_PATCH_PATH];
			[patchTask setArguments:[NSArray arrayWithObjects:baseMapPath, newMapPath, MOD_PATCH_DOWNLOAD_FILE, nil]];
			
			BOOL didPatch = YES;
			
			@try
			{
				[patchTask launch];
				[patchTask waitUntilExit];
			}
			@catch (NSException *exception)
			{
				NSLog(@"Failed patching: %@, %@", [exception name], [exception reason]);
				didPatch = NO;
			}
			
			NSString *mapHash = [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] md5Hash];
			if (mapHash && ![mapHash isEqualToString:[self md5HashFromFilePath:newMapPath]])
			{
				NSLog(@"Map hash %@ does not match with downloaded file", mapHash);
				didPatch = NO;
			}
			
			if (didPatch)
			{
				if ([self pendingPlugins] == nil && (![[appDelegate window] isKeyWindow] || ![NSApp isActive]))
				{
					[NSClassFromString(@"GrowlApplicationBridge")
					 notifyWithTitle:@"Download Finished"
					 description:[NSString stringWithFormat:@"You can now play %@", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]]
					 notificationName:@"ModDownloaded"
					 iconData:nil
					 priority:0
					 isSticky:NO
					 clickContext:@"ModDownloaded"];
				}
				
				addedMod = [self addModAtPath:newMapPath];
			}
			else
			{
				NSRunAlertPanel(@"Mod Installation Failed",
								@"%@ failed to install. Perhaps the downloaded patch file was corrupted.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:MOD_PATCH_DOWNLOAD_FILE error:nil];
		}
		
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		
		[self setModDownload:nil];
		
		[self setCurrentDownloadingPatch:nil];
		
		NSArray *plugins = [self pluginsNotInstalledFromPluginNames:[[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] plugins]];
		
		[self setCurrentDownloadingMapIdentifier:nil];
		
		if (plugins.count > 0)
		{
			[self installPluginsWithNames:plugins];
		}
		
		if (!addedMod)
		{
			[self setJoiningServer:nil];
		}
		else
		{
			if ([self pendingPlugins] == nil)
			{
				if ([[appDelegate window] isKeyWindow] && [NSApp isActive] && [self joiningServer])
				{
					[appDelegate joinServer:[self joiningServer]	];
				}
				[self setJoiningServer:nil];
			}
		}
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
	{
		NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Plugin_Unzip"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
		{
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		BOOL addedPlugin = NO;
		
		if ([[NSFileManager defaultManager] createDirectoryAtPath:unzipDirectory withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSTask *unzipTask = [[NSTask alloc] init];
			
			[unzipTask setLaunchPath:@"/usr/bin/unzip"];
			[unzipTask setArguments:[NSArray arrayWithObjects:@"-o", @"-q", @"-d", unzipDirectory, PLUGIN_DOWNLOAD_FILE, nil]];
			
			BOOL didUnzip = YES;
			
			@try
			{
				[unzipTask launch];
				[unzipTask waitUntilExit];
			}
			@catch (NSException *exception)
			{
				NSLog(@"Failed unzipping: %@, %@", [exception name], [exception reason]);
				didUnzip = NO;
			}
			
			if (didUnzip)
			{
				NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:unzipDirectory];
				NSString *file = nil;
				while (file = [directoryEnumerator nextObject])
				{
					if ([[file pathExtension] isEqualToString:@"mdplugin"] && ![[file lastPathComponent] hasPrefix:@"."])
					{
						BOOL preferEnabledState = ([[self currentDownloadingPlugin] globalMode] && [self pendingPlugins] == nil);
						addedPlugin = [self addPluginAtPath:[unzipDirectory stringByAppendingPathComponent:file] preferringEnabledState:preferEnabledState];
						break;
					}
				}
			}
			else
			{
				NSRunAlertPanel(@"Extension Installation Failed",
								@"%@ failed to install. Perhaps the downloaded file was corrupted.",
								@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
		}
		
		[appDelegate setStatus:nil];
		
		[self setModDownload:nil];
		
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
		[self setCurrentDownloadingPlugin:nil];
		
		if (!addedPlugin)
		{
			[self setPendingPlugins:nil];
		}
		else
		{
			if ([[self pendingPlugins] count] > 0)
			{
				[[self pendingPlugins] removeObjectAtIndex:0];
				if ([[self pendingPlugins] count] == 0)
				{
					[self setPendingPlugins:nil];
				}
				else
				{
					[self downloadPlugin:[[self pendingPlugins] objectAtIndex:0]];
				}
			}
		}
		
		if ([self pendingPlugins] == nil)
		{
			[self makePluginMenuItems];
			
			if ([self joiningServer] != nil)
			{
				if (addedPlugin && [[appDelegate window] isKeyWindow] && [NSApp isActive])
				{
					[appDelegate joinServer:[self joiningServer]];
				}
				[self setJoiningServer:nil];
			}
		}
	}
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	if (![download.request.URL isEqual:MULTIPLAYER_CODES_URL] && ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"]))
	{
		// Ensure currentContentLength won't exceed expectedContentLength
		if (currentContentLength < expectedContentLength)
		{
			currentContentLength += length;
			if (currentContentLength > expectedContentLength)
			{
				currentContentLength = expectedContentLength;
			}
			if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
			{
				[appDelegate setStatusWithoutWait:[NSString stringWithFormat:@"Installing Extension %@... (%d%%)", [[self currentDownloadingPlugin] name], (int)((100.0 * currentContentLength) / expectedContentLength)]];
			}
			else
			{
				[appDelegate setStatusWithoutWait:[NSString stringWithFormat:@"Installing %@... (%d%%)", [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name], (int)((100.0 * currentContentLength) / expectedContentLength)]];
			}
		}
	}
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	if (![download.request.URL isEqual:MULTIPLAYER_CODES_URL] && ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"]))
	{
		expectedContentLength = [response expectedContentLength];
		currentContentLength = 0;
		
		[cancelButton setHidden:NO];
		[refreshButton setHidden:YES];
	}
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte
{
	currentContentLength = startingByte;
	expectedContentLength = [response expectedContentLength];
	
	resumeTimeoutDate = nil;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	NSLog(@"Failed to download file: %@, %@", [[download request] URL], [error localizedDescription]);
	
	[self setJoiningServer:nil];
	
	if ([[[download request] URL] isEqual:MULTIPLAYER_CODES_URL])
	{
		isDownloadingModList = NO;
		[self setPendingDownload:nil];
	}
	else if ([[self directoryNameFromRequest:download.request] isEqualToString:@"mods"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"patches"] || [[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
	{
		NSString *destination = nil;
		
		if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
		{
			destination = PLUGIN_DOWNLOAD_FILE;
		}
		else
		{
			destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
		}
		
		if (!resumeTimeoutDate)
		{
			resumeTimeoutDate = [NSDate date];
		}
		
		if ([[NSDate date] timeIntervalSinceDate:resumeTimeoutDate] <= 7.0 && [download resumeData])
		{
			NSURLDownload *newDownload = [[NSURLDownload alloc] initWithResumeData:[download resumeData] delegate:self path:destination];
			[newDownload setDeletesFileUponFailure:NO];
			[self setModDownload:newDownload];
		}
		else
		{
			if ([[self directoryNameFromRequest:download.request] isEqualToString:@"plug-ins"])
			{
				NSRunAlertPanel(@"Extension Download Failed",
								@"%@ failed to finish downloading.",
								@"OK", nil, nil, [[self currentDownloadingPlugin] name]);
			}
			else
			{
				NSRunAlertPanel(@"Mod Download Failed",
								@"%@ failed to finish downloading.",
								@"OK", nil, nil, [[modListDictionary objectForKey:[self currentDownloadingMapIdentifier]] name]);
			}
			
			[self setCurrentDownloadingMapIdentifier:nil];
			[self setCurrentDownloadingPatch:nil];
			[self setCurrentDownloadingPlugin:nil];
			
			[appDelegate setStatus:nil];
			
			[cancelButton setHidden:YES];
			[refreshButton setHidden:NO];
			[self setModDownload:nil];
			[self setPendingPlugins:nil];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
	}
}

- (NSString *)originalMapPathFromIdentifier:(NSString *)identifier
{
	NSString *identifierWithPathExtension = [identifier stringByAppendingPathExtension:@"map"];
	return [[NSArray arrayWithObjects:@"bloodgulch", @"crossing", @"barrier", nil] containsObject:identifier] ? [[[appDelegate resourceGameDataPath] stringByAppendingPathComponent:@"Maps"] stringByAppendingPathComponent:identifierWithPathExtension] : [MAPS_DIRECTORY stringByAppendingPathComponent:identifierWithPathExtension];
}

- (NSString *)md5HashFromFilePath:(NSString *)filePath
{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	return [MDHashDigest md5HashFromBytes:data.bytes length:(CC_LONG)data.length];
}

- (void)downloadMod:(NSString *)mapIdentifier
{
	if (![self isValidBuildNumber:mapIdentifier])
	{
		NSLog(@"Invalid build number from identifier: %@", mapIdentifier);
		return;
	}
	
	NSString *modName =  [[modListDictionary objectForKey:mapIdentifier] name];
	if (!modName)
	{
		NSLog(@"Could not find map identifier %@", mapIdentifier);
		if (![self didDownloadModList])
		{
			NSLog(@"Trying to re-download mod list...");
			[self setPendingDownload:mapIdentifier];
			[self downloadModList];
		}
		return;
	}
	
	[self setCurrentDownloadingMapIdentifier:mapIdentifier];
	
	[appDelegate setStatus:[NSString stringWithFormat:@"Installing %@...", modName]];
	
	// Find out if we can download a patched version
	MDModPatch *foundPatch = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:BS_PATCH_PATH])
	{
		for (MDModPatch *patch in [[modListDictionary objectForKey:mapIdentifier] patches])
		{
			NSString *mapPath = [self originalMapPathFromIdentifier:[patch baseIdentifier]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:mapPath])
			{
				if ([[self md5HashFromFilePath:mapPath] isEqualToString:[patch baseHash]])
				{
					foundPatch = patch;
					break;
				}
			}
		}
	}
	
	[self setCurrentDownloadingPatch:foundPatch];
	
	resumeTimeoutDate = nil;
	
	NSURL *downloadURL = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_URL : MOD_DOWNLOAD_URL;
	NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	
	NSString *destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
	[download setDestination:destination allowOverwrite:YES];
	[download setDeletesFileUponFailure:NO];
	[self setModDownload:download];
}

- (void)downloadPlugin:(MDPluginListItem *)plugin
{
	[self setCurrentDownloadingPlugin:plugin];
	
	[appDelegate setStatus:[NSString stringWithFormat:@"Installing %@ (Extension)...", plugin.name]];
	
	resumeTimeoutDate = nil;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:PLUGIN_DOWNLOAD_URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	[download setDestination:PLUGIN_DOWNLOAD_FILE allowOverwrite:YES];
	[download setDeletesFileUponFailure:YES];
	[self setModDownload:download];
}

- (void)requestModDownload:(NSString *)mapIdentifier andJoinServer:(MDServer *)server
{
	MDModListItem *listItem = [modListDictionary objectForKey:mapIdentifier];
	if (![self reportWhatIsInstalling])
	{
		NSString *modName = [listItem name];
		
		MDModListItem *modItem = nil;
		for (MDModListItem *item in [self localModItems])
		{
			if ([[item name] isEqualToString:modName] && (modItem == nil || [self buildNumberFromMapIdentifier:[modItem identifier]] > [self buildNumberFromMapIdentifier:[item identifier]]))
			{
				modItem = item;
			}
		}
		
		if (modItem != nil)
		{
			MDModListItem *currentListItem = [modListDictionary objectForKey:[modItem identifier]];
			int currentBuildNumber = [self buildNumberFromMapIdentifier:[currentListItem identifier]];
			int desiredBuildNumber = [self buildNumberFromMapIdentifier:mapIdentifier];
			
			if (NSRunAlertPanel(@"Modded Game",
								@"Do you want to install %@ (v%@) in order to join this game? You currently have %@ version (v%@) installed.",
								@"Install", @"Cancel", nil, [listItem name],  [listItem version], currentBuildNumber < desiredBuildNumber ? @"an older" : @"a different", [currentListItem version]) == NSOKButton)
			{
				[self setJoiningServer:server];
				[self downloadMod:mapIdentifier];
			}
		}
		else if (NSRunAlertPanel(@"Modded Game",
							     @"Do you want to install %@ in order to join this game?",
							     @"Install", @"Cancel", nil, [listItem name]) == NSOKButton)
		{
			[self setJoiningServer:server];
			[self downloadMod:mapIdentifier];
		}
	}
}

- (NSArray *)pluginsNotInstalledFromPluginNames:(NSArray *)pluginNames onlyNeedsInstalling:(BOOL *)needsInstalling
{
	NSMutableArray *pluginNamesToInstall = [NSMutableArray array];
	
	for (NSString *pluginName in pluginNames)
	{
		MDPluginListItem *matchingPlugin = nil;
		for (NSMenuItem *menuItem in [self pluginMenuItems])
		{
			MDPluginListItem *pluginItem = [menuItem representedObject];
			if ([pluginItem.name isEqualToString:pluginName])
			{
				matchingPlugin = pluginItem;
				break;
			}
		}
		
		if (matchingPlugin == nil)
		{
			[pluginNamesToInstall addObject:pluginName];
			if (needsInstalling != NULL)
			{
				*needsInstalling = YES;
			}
			continue;
		}
		
		MDPluginListItem *onlineItem = [pluginListDictionary objectForKey:pluginName];
		if (onlineItem == nil || onlineItem.build == 0) continue;
		
		if (matchingPlugin.build < onlineItem.build)
		{
			[pluginNamesToInstall addObject:pluginName];
		}
	}
	
	return pluginNamesToInstall;
}

- (NSArray *)pluginsNotInstalledFromPluginNames:(NSArray *)pluginNames
{
	return [self pluginsNotInstalledFromPluginNames:pluginNames onlyNeedsInstalling:NULL];
}

- (BOOL)requestPluginDownloadIfNeededFromMod:(NSString *)mapIdentifier andJoinServer:(MDServer *)server
{
	if ([self reportWhatIsInstalling]) return YES;
	
	MDModListItem *modItem = [modListDictionary objectForKey:mapIdentifier];
	
	NSArray *pluginNames = [modItem plugins];
	BOOL needsInstalling = NO;
	NSArray *pluginNamesToInstall = [self pluginsNotInstalledFromPluginNames:pluginNames onlyNeedsInstalling:&needsInstalling];
	
	if (pluginNamesToInstall.count > 0)
	{
		if (NSRunAlertPanel(@"Modded Game",
							@"Do you want to %@ %lu extension %@ in order to join this game?",
							@"Install", @"Cancel", nil, needsInstalling ? @"install" : @"update", (unsigned long)pluginNamesToInstall.count, pluginNamesToInstall.count != 1 ? @"s" : @"") == NSOKButton)
		{
			[self setJoiningServer:server];
			[self installPluginsWithNames:pluginNamesToInstall];
		}
	}
	
	return pluginNamesToInstall.count > 0;
}

- (void)openURL:(NSString *)url
{
	if ([self isInitiated])
	{
		NSString *modPrefix = @"halomdinstall://";
		NSString *pluginPrefix = @"halomdplugininstall://";
		if ([url hasPrefix:modPrefix])
		{
			[self installOnlineModWithIdentifier:[url substringFromIndex:[modPrefix length]]];
		}
		else if ([url hasPrefix:pluginPrefix])
		{
			[self installPluginsWithNames:[NSArray arrayWithObject:[[url substringFromIndex:[pluginPrefix length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
	}
	else
	{
		[self setUrlToOpen:url];
	}
}

- (void)initiateAndForceDownloadList:(NSNumber *)shouldForceDownloadList
{
	NSString *modsListPath = MODS_LIST_PATH;
	
	if (!gJsonSerializaionExists)
	{
		NSString *jsonPath = MODS_LIST_PATH_WITH_EXTENSION(@"json");
		if ([[NSFileManager defaultManager] fileExistsAtPath:jsonPath])
		{
			[[NSFileManager defaultManager] removeItemAtPath:jsonPath error:NULL];
			
			// remove old plist from way back ages ago (before we ever used json)
			if ([[NSFileManager defaultManager] fileExistsAtPath:modsListPath])
			{
				[[NSFileManager defaultManager] removeItemAtPath:modsListPath error:NULL];
			}
		}
	}
	
	[self makeModMenuItems];
	[self makeModsList]; // In case the file doesn't download, use local copy
	
	[self makePluginMenuItems];
	[self makePluginsList];
	
	id dateLastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:MODS_LIST_DOWNLOAD_TIME_KEY];
	if ([shouldForceDownloadList boolValue] || ![[NSFileManager defaultManager] fileExistsAtPath:modsListPath] || [dateLastChecked isKindOfClass:[NSString class]] || [[NSDate date] timeIntervalSinceDate:dateLastChecked] > 10.0 * 60)
	{
		if ([shouldForceDownloadList boolValue])
		{
			NSLog(@"Forcing mod list download...");
		}
		[self downloadModList];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:MODS_LIST_DOWNLOAD_TIME_KEY];
	}
	else
	{
		[self stopAndStartDownloadModListTimer];
	}
	
	events = [[SCEvents alloc] init];
	[events setDelegate:self];
	
	NSArray *watchingPaths = [NSArray arrayWithObjects:MAPS_DIRECTORY, PLUGINS_DIRECTORY, PLUGINS_DISABLED_DIRECTORY, nil];
	[events startWatchingPaths:watchingPaths];
	
	[self setIsInitiated:YES];
	
	if ([self urlToOpen])
	{
		[self openURL:[self urlToOpen]];
		[self setUrlToOpen:nil];
	}
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event
{
	if ([event.eventPath isEqualToString:MAPS_DIRECTORY])
	{
		[self updateOnlineModStates];
		[self makeModMenuItems];
		[appDelegate updateHiddenServers];
	}
	else
	{
		[self makePluginMenuItems];
	}
}

- (IBAction)cancelInstallation:(id)sender
{
	if ([self modDownload])
	{
		[[self modDownload] cancel];
		[self setModDownload:nil];
		
		if ([self currentDownloadingPatch] || [self currentDownloadingMapIdentifier])
		{
			NSString *destination = [self currentDownloadingPatch] ? MOD_PATCH_DOWNLOAD_FILE : MOD_DOWNLOAD_FILE;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
		else if ([self currentDownloadingPlugin])
		{
			NSString *destination = PLUGIN_DOWNLOAD_FILE;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destination])
			{
				[[NSFileManager defaultManager] removeItemAtPath:destination error:NULL];
			}
		}
		
		[self setCurrentDownloadingMapIdentifier:nil];
		[self setCurrentDownloadingPatch:nil];
		[self setCurrentDownloadingPlugin:nil];
		[self setPendingPlugins:nil];
		[self setJoiningServer:nil];
		[appDelegate setStatus:nil];
		[cancelButton setHidden:YES];
		[refreshButton setHidden:NO];
	}
}

- (IBAction)revealMapsInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:MAPS_DIRECTORY
					 inFileViewerRootedAtPath:[[appDelegate applicationSupportPath] stringByAppendingPathComponent:@"GameData"]];
}

@end
