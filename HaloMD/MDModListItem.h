//
//  MDModListItem.h
//  HaloMD
//
//  Created by null on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDModListItem : NSObject
{
	NSString *identifier;
	NSString *version;
	NSString *name;
	NSString *description;
	NSString *md5Hash;
	NSArray *patches;
}

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *md5Hash;
@property (nonatomic, retain) NSArray *patches;

@end
