//
//  MDPreferencesWindowController.m
//  HaloMD
//
//  Created by null on 12/23/16.
//  Copyright © 2016 Pennsylvania State University. All rights reserved.
//

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
