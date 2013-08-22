//
//  MDNetworking.h
//  HaloMD
//
//  Created by null on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDNetworking : NSObject

+ (NSString *)addressFromHost:(NSString *)host;

+ (void)retrieveServers:(id)delegate;

@end
