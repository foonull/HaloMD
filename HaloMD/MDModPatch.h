//
//  MDModPatch.h
//  HaloMD
//
//  Created by null on 4/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDModPatch : NSObject
{
	NSString *baseIdentifier;
	NSString *baseHash;
	NSString *path;
}

@property (nonatomic, copy) NSString *baseIdentifier;
@property (nonatomic, copy) NSString *baseHash;
@property (nonatomic, copy) NSString *path;

@end
