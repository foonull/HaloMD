//
//  MDHyperLink.h
//  HaloMD
//
//  Created by null on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// Copied from http://developer.apple.com/library/mac/#qa/qa1487/_index.html

#import <Foundation/Foundation.h>

@interface NSAttributedString (MDHyperlink)

+ (id)MDHyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;

@end
