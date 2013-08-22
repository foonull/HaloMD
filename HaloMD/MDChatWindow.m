//
//  MDChatWindow.m
//  HaloMD
//
//  Created by null on 5/9/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "MDChatWindow.h"

@implementation MDChatWindow

- (void)keyDown:(NSEvent *)theEvent
{
	[self makeFirstResponder:chatField];
	[chatField insertText:[theEvent charactersIgnoringModifiers]];
}

@end
