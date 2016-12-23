/*
 * Copyright (c) 2016, Null <foo.null@yahoo.com>
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

#import "MDPreferencesWindowController.h"
#import "MDModsController.h"

typedef enum {
	MDModDatabaseMGMURLType = 0,
	MDModDatabaseGalaxyVergeURLType = 1
} MDModDatabaseURLType;

@implementation MDPreferencesWindowController
{
	IBOutlet NSButton *_mgmModDatabaseRadioButton;
	IBOutlet NSButton *_galaxyVergeModDatabaseRadioButton;
}

- (id)init
{
	self = [super initWithWindowNibName:NSStringFromClass([self class])];
	if (self != nil)
	{
	}
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	BOOL usesMirror = USES_MODS_MIRROR;
	
	_galaxyVergeModDatabaseRadioButton.state = usesMirror ? NSOnState : NSOffState;
	_mgmModDatabaseRadioButton.state = usesMirror ? NSOffState : NSOnState;
}

- (IBAction)changeModDatabaseURL:(id)sender
{
	switch ((MDModDatabaseURLType)[sender tag])
	{
		case MDModDatabaseMGMURLType:
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:USES_MODS_MIRROR_KEY];
			break;
		case MDModDatabaseGalaxyVergeURLType:
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:USES_MODS_MIRROR_KEY];
			break;
		default:
			NSLog(@"Error: unknown mod database url type");
			break;
	}
}

@end
