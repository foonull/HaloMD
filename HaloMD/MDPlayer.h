//
//  MDPlayer.h
//  HaloMD
//
//  Created by null on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDPlayer : NSObject
{
	NSString *name;
	NSString *score;
}

@property (copy, readwrite) NSString *name;
@property (copy, readwrite) NSString *score;

@end
