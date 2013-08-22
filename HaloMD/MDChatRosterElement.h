//
//  MDChatRosterElement.h
//  HaloMD
//
//  Created by null on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDChatRosterElement : NSObject
{
	NSString *name;
	NSString *jabberIdentifier;
	NSString *status;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *jabberIdentifier;
@property (nonatomic, copy) NSString *status;

@end
