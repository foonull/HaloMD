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
//  MDInspectorController.m
//  HaloMD
//
//  Created by null on 3/10/12.
//

#import "MDInspectorController.h"
#import "AppDelegate.h"
#import "MDServer.h"
#import "MDPlayer.h"

#define INSPECTOR_KEY @"INSPECTOR_SHOULD_DISPLAY_KEY"

@implementation MDInspectorController

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:INSPECTOR_KEY]];
}

- (void)initiateGameInspector
{
	[inspectorPanel setDelegate:self];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:INSPECTOR_KEY])
	{
		[self showGameInspector:nil];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] == inspectorPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:INSPECTOR_KEY];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)theMenuItem
{
	if ([theMenuItem action] == @selector(showGameInspector:))
	{
		if ([inspectorPanel isVisible])
		{
			[theMenuItem setTitle:@"Hide Inspector"];
		}
		else
		{
			[theMenuItem setTitle:@"Show Inspector"];
		}
		
		if (![[appController window] isVisible])
		{
			return NO;
		}
	}
	else if ([theMenuItem action] == @selector(nextTab:) || [theMenuItem action] == @selector(previousTab:))
	{
		if (![inspectorPanel isVisible])
		{
			return NO;
		}
	}
	return YES;
}

- (void)updateInspectorInformation
{
	BOOL shouldPutEmptyInformation = YES;
	MDServer *server = [appController selectedServer];
	
	if ([server valid])
	{
		[gametypeTextField setStringValue:[server gametype]];
		[scoreLimitTextField setStringValue:[server scoreLimit]];
		[teamPlayTextField setStringValue:[server teamPlay]];
		[addressTextField setStringValue:[[server ipAddress] stringByAppendingFormat:@":%d", [server portNumber]]];
		[dedicatedTextField setStringValue:[server dedicated]];
		
		shouldPutEmptyInformation = NO;
	}
	
	if (shouldPutEmptyInformation)
	{
		[gametypeTextField setStringValue:@""];
		[scoreLimitTextField setStringValue:@""];
		[teamPlayTextField setStringValue:@""];
		[addressTextField setStringValue:@""];
		[dedicatedTextField setStringValue:@""];
	}
	
	[playersTable reloadData];
}

- (IBAction)showGameInspector:(id)sender
{
	if ([inspectorPanel isVisible])
	{
		[inspectorPanel close];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:INSPECTOR_KEY];
		[self updateInspectorInformation];
		[inspectorPanel orderFront:nil];
	}
}

- (void)switchTabs
{
	if ([[[tabView selectedTabViewItem] identifier] isEqualToString:@"general"])
	{
		[tabView selectTabViewItemWithIdentifier:@"players"];
	}
	else
	{
		[tabView selectTabViewItemWithIdentifier:@"general"];
	}
}

- (IBAction)nextTab:(id)sender
{
	[self switchTabs];
}

- (IBAction)previousTab:(id)sender
{
	[self switchTabs];
}

- (void)cleanup
{
	// Change back to 'general' position & size so when the app re-launches and when it auto-changes to 'players' view, the position will be correct
	if (![[[tabView selectedTabViewItem] identifier] isEqualToString:@"general"])
	{
		[inspectorPanel setFrame:NSMakeRect([inspectorPanel frame].origin.x + [inspectorPanel frame].size.width - [inspectorPanel minSize].width, [inspectorPanel frame].origin.y + [inspectorPanel frame].size.height - [inspectorPanel minSize].height, [inspectorPanel minSize].width, [inspectorPanel minSize].height)
						 display:NO
						 animate:NO];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if ([[tabViewItem identifier] isEqualToString:@"general"])
	{
		[inspectorPanel setFrame:NSMakeRect([inspectorPanel frame].origin.x + [inspectorPanel frame].size.width - [inspectorPanel minSize].width, [inspectorPanel frame].origin.y + [inspectorPanel frame].size.height - [inspectorPanel minSize].height, [inspectorPanel minSize].width, [inspectorPanel minSize].height)
						 display:YES
						 animate:YES];
	}
	else
	{
		[inspectorPanel setFrame:NSMakeRect([inspectorPanel frame].origin.x + [inspectorPanel frame].size.width - [inspectorPanel maxSize].width, [inspectorPanel frame].origin.y + [inspectorPanel frame].size.height - [inspectorPanel maxSize].height, [inspectorPanel maxSize].width, [inspectorPanel maxSize].height)
						 display:YES
						 animate:YES];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[[appController selectedServer] players] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSArray *playersArray = [[appController selectedServer] players];
	if (rowIndex >= 0 && (NSUInteger)rowIndex < [playersArray count])
	{
		MDPlayer *player = [playersArray objectAtIndex:rowIndex];
		
		if ([[tableColumn identifier] isEqualToString:@"name"])
		{
			return [player name];
		}
		else if ([[tableColumn identifier] isEqualToString:@"score"])
		{
			return [player score];
		}
	}
	
	return nil;
}

@end
