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
#import "mach_override.h"
#import "MDPlugin.h"
#import "JSONKit.h"

#define MDGlobalPlugin @"MDGlobalPlugin"
#define MDMapPlugin @"MDMapPlugin"

static NSString *gActiveMap;
static NSMutableArray *gGlobalLoadedPlugins;
static NSMutableDictionary *gLoadedPluginsDictionary;
static NSMutableDictionary *gMapBasedPluginNamesDictionary;
static NSMutableDictionary *gMapBasedPluginsDictionary;

static NSString *gThirdPartyPluginsDirectory;
static NSString *gThirdPartyPluginsDisabledDirectory;

static void loadMapBasedPlugin(NSString *mapName, NSString *pluginName, NSString *filePath)
{
	NSBundle *pluginBundle = [NSBundle bundleWithPath:filePath];
	if (pluginBundle != nil)
	{
		NSNumber *modPluginValue = [[pluginBundle infoDictionary] objectForKey:MDMapPlugin];
		if (modPluginValue != nil && [modPluginValue boolValue])
		{
			id <MDPlugin> newPluginInstance = [[pluginBundle principalClass] alloc];
			if ([newPluginInstance respondsToSelector:@selector(initWithMode:)])
			{
				newPluginInstance = [newPluginInstance initWithMode:MDPluginMapMode];
			}
			else
			{
				newPluginInstance = [(id)newPluginInstance init];
			}
			if (newPluginInstance != nil)
			{
				[gLoadedPluginsDictionary setObject:newPluginInstance forKey:pluginName];
				
				if (gMapBasedPluginsDictionary == nil)
				{
					gMapBasedPluginsDictionary = [[NSMutableDictionary alloc] init];
				}
				
				NSMutableArray *associatedPlugins = [gMapBasedPluginsDictionary objectForKey:mapName];
				if (associatedPlugins == nil)
				{
					associatedPlugins = [[[NSMutableArray alloc] init] autorelease];
				}
				
				[associatedPlugins addObject:newPluginInstance];
				[gMapBasedPluginsDictionary setObject:associatedPlugins forKey:mapName];
				
				[newPluginInstance release];
			}
		}
	}
}

static void loadMapBasedPlugins(NSString *mapName)
{
	NSArray *pluginNames = [gMapBasedPluginNamesDictionary objectForKey:mapName];
	for (NSString *pluginName in pluginNames)
	{
		if (![pluginName isKindOfClass:[NSString class]] || [gLoadedPluginsDictionary objectForKey:pluginName] != nil)
		{
			continue;
		}
		
		NSString *normalPluginPath = [[gThirdPartyPluginsDirectory stringByAppendingPathComponent:pluginName] stringByAppendingPathExtension:@"mdplugin"];
		NSString *disabledPluginPath = [[gThirdPartyPluginsDisabledDirectory stringByAppendingPathComponent:pluginName] stringByAppendingPathExtension:@"mdplugin"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:normalPluginPath])
		{
			loadMapBasedPlugin(mapName, pluginName, normalPluginPath);
		}
		else if ([[NSFileManager defaultManager] fileExistsAtPath:disabledPluginPath])
		{
			loadMapBasedPlugin(mapName, pluginName, disabledPluginPath);
		}
	}
}

static void sendPluginMapChange(SEL selector, NSString *mapName)
{
	NSMutableArray *mapPlugins = [gMapBasedPluginsDictionary objectForKey:mapName];
	for (id <MDPlugin> plugin in mapPlugins)
	{
		if ([plugin respondsToSelector:selector])
		{
			[plugin performSelector:selector withObject:mapName];
		}
	}
	
	for (id <MDPlugin> plugin in gGlobalLoadedPlugins)
	{
		if ([plugin respondsToSelector:selector])
		{
			[plugin performSelector:selector withObject:mapName];
		}
	}
}

static void *(*haloMapBegins)(const char *);
static void *mdMapBegins(const char *mapName)
{
	void *result = NULL;
	@autoreleasepool
	{
		if (gActiveMap != nil)
		{
			sendPluginMapChange(@selector(mapDidEnd:), gActiveMap);
		}
		
		[gActiveMap release];
		gActiveMap = [[NSString stringWithUTF8String:mapName] retain];
		
		loadMapBasedPlugins(gActiveMap);
		
		sendPluginMapChange(@selector(mapWillBegin:), gActiveMap);
		
		result = haloMapBegins(mapName);
		
		sendPluginMapChange(@selector(mapDidBegin:), gActiveMap);
	}
	
	return result;
}

static void addPluginsInDirectory(NSMutableArray *pluginPaths, NSString *directory)
{
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
	for (NSString *pluginName in directoryEnumerator)
	{
		if ([[pluginName pathExtension] isEqualToString:@"mdplugin"])
		{
			[pluginPaths addObject:[directory stringByAppendingPathComponent:pluginName]];
		}
		[directoryEnumerator skipDescendents];
	}
}

static NSDictionary *modListDictionaryFromJSONPath(NSString *jsonPath)
{
	NSDictionary *modsDictionary = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:jsonPath])
	{
		NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
		if (jsonData != nil)
		{
			Class jsonSerializationClass = NSClassFromString(@"NSJSONSerialization");
			if (jsonSerializationClass != nil)
			{
				NSError *error = nil;
				modsDictionary = [jsonSerializationClass JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
			}
			else
			{
				modsDictionary = [[JSONDecoder decoder] objectWithData:jsonData];
			}
		}
	}
	return [modsDictionary objectForKey:@"Mods"];
}

static void addMapBasedPlugins(NSMutableDictionary *mapBasedPluginNamesDictionary, NSDictionary *modsDictionary, BOOL printError)
{
	if (modsDictionary == nil)
	{
		if (printError)
		{
			NSLog(@"Error: Plugin handler failed to load mod list dictionary!");
		}
	}
	else
	{
		for (NSDictionary *modItem in modsDictionary)
		{
			NSArray *pluginNames = [modItem objectForKey:@"plugins"];
			if (pluginNames != nil && [pluginNames isKindOfClass:[NSArray class]])
			{
				NSString *mapIdentifier = [modItem objectForKey:@"identifier"];
				if (mapIdentifier != nil && [mapBasedPluginNamesDictionary objectForKey:mapIdentifier] == nil)
				{
					[mapBasedPluginNamesDictionary setObject:pluginNames forKey:mapIdentifier];
				}
			}
		}
	}
}

static __attribute__((constructor)) void init()
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		// Reserve memory halo wants before halo initiates, should help fix a bug in 10.9 where GPU drivers may have been loaded here
		mmap((void *)0x40000000, 0x1b40000, PROT_READ | PROT_WRITE, MAP_FIXED | MAP_ANON | MAP_PRIVATE, -1, 0);
		
		@autoreleasepool
		{
			NSMutableArray *pluginPaths = [NSMutableArray array];
			gGlobalLoadedPlugins = [[NSMutableArray alloc] init];
			gLoadedPluginsDictionary = [[NSMutableDictionary alloc] init];
			
			NSString *builtinPluginDirectory = [[[NSProcessInfo processInfo] environment] objectForKey:@"MD_BUILTIN_PLUGIN_DIRECTORY"];
			
			addPluginsInDirectory(pluginPaths, builtinPluginDirectory);
			
			NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
			NSString *appSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
			NSString *haloMDAppSupportPath = [appSupportPath stringByAppendingPathComponent:@"HaloMD"];
			
			NSString *modsListPath = [haloMDAppSupportPath stringByAppendingPathComponent:@"HaloMD_mods_list.json"];
			NSString *modsDevListPath = [haloMDAppSupportPath stringByAppendingPathComponent:@"HaloMD_mods_list_dev.json"];
			
			gMapBasedPluginNamesDictionary = [[NSMutableDictionary alloc] init];
			addMapBasedPlugins(gMapBasedPluginNamesDictionary, modListDictionaryFromJSONPath(modsListPath), YES);
			addMapBasedPlugins(gMapBasedPluginNamesDictionary, modListDictionaryFromJSONPath(modsDevListPath), NO);
			
			gThirdPartyPluginsDirectory = [[haloMDAppSupportPath stringByAppendingPathComponent:@"PlugIns"] copy];
			gThirdPartyPluginsDisabledDirectory = [[haloMDAppSupportPath stringByAppendingPathComponent:@"PlugIns (Disabled)"] copy];
			
			addPluginsInDirectory(pluginPaths, gThirdPartyPluginsDirectory);
			
			for (NSString *pluginPath in pluginPaths)
			{
				NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
				if (pluginBundle != nil)
				{
					NSString *pluginName = [[[pluginBundle bundlePath] lastPathComponent] stringByDeletingPathExtension];
					if ([gLoadedPluginsDictionary objectForKey:pluginName] != nil)
					{
						NSLog(@"Ignoring plugin %@ since plugin with same name was already loaded", [pluginBundle bundlePath]);
					}
					else
					{
						NSNumber *globalPluginValue = [[pluginBundle infoDictionary] objectForKey:MDGlobalPlugin];
						if (globalPluginValue != nil && [globalPluginValue boolValue])
						{
							id <MDPlugin> newPluginInstance = [[pluginBundle principalClass] alloc];
							if ([newPluginInstance respondsToSelector:@selector(initWithMode:)])
							{
								newPluginInstance = [newPluginInstance initWithMode:MDPluginGlobalMode];
							}
							else
							{
								newPluginInstance = [(id)newPluginInstance init];
							}
							
							if (newPluginInstance != nil)
							{
								[gLoadedPluginsDictionary setObject:newPluginInstance forKey:pluginName];
								[gGlobalLoadedPlugins addObject:newPluginInstance];
								[newPluginInstance release];
							}
						}
					}
				}
			}
			
			mach_override_ptr((void *)0x70edc, mdMapBegins, (void **)&haloMapBegins);
		}
		
		initialized = YES;
	}
}
