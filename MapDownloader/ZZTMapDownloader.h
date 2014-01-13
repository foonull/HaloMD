//
//  ZZTMapDownloader.h
//  MapDownloader
//
//  Created by Paul Whitcomb on 11/29/13.
//  Copyright (c) 2013 Zero2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDPlugin.h"

@interface ZZTMapDownloader : NSObject <MDPlugin, NSURLDownloadDelegate>
{
    NSString *_mapIdentifier; //the identifier of our downloading map. ex: bune_1
    NSString *_patchToMap; //the identifier of the map we will patch. nil if we aren't patching.
    NSURLDownload *_activeDownload;
}

@property (nonatomic, copy) NSString *mapIdentifier;
@property (nonatomic, copy) NSString *patchToMap;
@property (nonatomic, retain) NSURLDownload *activeDownload;

typedef enum {
    NONE = 0x0,
    WHITE = 0x343aa0,
    GREY = 0x343ab0,
    BLACK = 0x343ac0,
    RED = 0x343ad0,
    GREEN = 0x343ae0,
    BLUE = 0x343af0,
    CYAN = 0x343b00,
    YELLOW = 0x343b10,
    MAGENTA = 0x343b20,
    PINK = 0x343b30,
    COBALT = 0x343b40,
    ORANGE = 0x343b50,
    PURPLE = 0x343b60,
    TURQUOISE = 0x343b70,
    DARK_GREEN = 0x343b80,
    SALMON = 0x343b90,
    DARK_PINK = 0x343ba0
} ConsoleColor; //Colorful console colors!

struct unicodeStringTag {
    uint32_t referencesCount;
    struct unicodeStringReference *references;
    uint32_t zero;
};
struct unicodeStringReference {
    uint32_t length;
    uint32_t unknown;
    uint32_t unknown2;
    unichar *string;
    uint32_t zero;
};
@end