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
//  MDGameFavoritesWindowController.m
//  HaloMD
//
//  Created by null on 12/19/13.
//

#import "MDGameFavoritesWindowController.h"
#import "AppDelegate.h"

@implementation MDGameFavoritesWindowController

@synthesize favoritesPath = _favoritesPath;

- (id)init
{
	self = [super initWithWindowNibName:NSStringFromClass([self class])];
	return self;
}

- (void)attachToParentWindow:(NSWindow *)parentWindow andShowFavoritesFromPath:(NSString *)favoritesPath
{
	NSError *error = nil;
	NSString *favorites = [[NSString alloc] initWithContentsOfFile:favoritesPath encoding:NSUTF8StringEncoding error:&error];
	
	if (favorites == nil)
	{
		NSLog(@"Error loading favorites file!");
		NSLog(@"%@", error);
	}
	else
	{
		self.favoritesPath = favoritesPath;
		[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:NULL];
		[[[_textView textStorage] mutableString] setString:favorites];
	}
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:self.window];
	[self.window close];
}

- (IBAction)save:(id)sender
{
	NSString *newFavorites = [[[_textView textStorage] mutableString] copy];
	
	NSError *error = nil;
	if (![newFavorites writeToFile:self.favoritesPath atomically:YES encoding:NSUTF8StringEncoding error:&error])
	{
		NSLog(@"Error: failed to write favorites at %@", self.favoritesPath);
		NSLog(@"%@", error);
	}
	
	self.favoritesPath = nil;
	[NSApp endSheet:self.window];
	[self.window close];
}

@end
