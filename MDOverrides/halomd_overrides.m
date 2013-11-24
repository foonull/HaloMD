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
			
			NSString *builtinPluginDirectory = [[[NSProcessInfo processInfo] environment] objectForKey:@"MD_BUILTIN_PLUGIN_DIRECTORY"];
			
			addPluginsInDirectory(pluginPaths, builtinPluginDirectory);
			
			NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
			NSString *appSupportPath = [libraryPath stringByAppendingPathComponent:@"Application Support"];
			NSString *thirdPartyPluginsPath = [[appSupportPath stringByAppendingPathComponent:@"HaloMD"] stringByAppendingPathComponent:@"PlugIns"];
			
			addPluginsInDirectory(pluginPaths, thirdPartyPluginsPath);
			
			for (NSString *pluginPath in pluginPaths)
			{
				NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
				[[[pluginBundle principalClass] alloc] init];
			}
		}
		
		initialized = YES;
	}
}
