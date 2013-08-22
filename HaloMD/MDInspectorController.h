//
//  MDInspectorController.h
//  HaloMD
//
//  Created by null on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface MDInspectorController : NSObject <NSApplicationDelegate, NSWindowDelegate>
{
	IBOutlet AppDelegate *appController;
	
	IBOutlet NSPanel *inspectorPanel;
	IBOutlet NSTextField *addressTextField;
	IBOutlet NSTextField *gametypeTextField;
	IBOutlet NSTextField *teamPlayTextField;
	IBOutlet NSTextField *scoreLimitTextField;
	IBOutlet NSTextField *dedicatedTextField;
	IBOutlet NSTableView *playersTable;
	IBOutlet NSTabView *tabView;
}

- (void)cleanup;

- (IBAction)showGameInspector:(id)sender;
- (IBAction)nextTab:(id)sender;
- (IBAction)previousTab:(id)sender;
- (void)initiateGameInspector;
- (void)updateInspectorInformation;

@end
