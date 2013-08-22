//
//  MDHyperLink.m
//  HaloMD
//
//  Created by null on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MDHyperLink.h"

@implementation NSAttributedString (MDHyperlink)

+ (id)MDHyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
	NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
	NSRange range = NSMakeRange(0, [attrString length]);
	
	[attrString beginEditing];
	[attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
	
	// make the text appear in blue
	[attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
	
	// next make the text appear with an underline
	[attrString addAttribute: NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
	
	[attrString endEditing];
	
	return [attrString autorelease];
}

@end
