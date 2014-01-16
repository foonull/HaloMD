//
//  ZZTMapDownloader.m
//  MapDownloader
//
//  Created by Paul Whitcomb on 11/29/13.
//  Copyright (c) 2013 Zero2. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "ZZTMapDownloader.h"
#import "mach_override.h"
#import "mztools.h"
#import "bspatch.h"

#define MOD_DOWNLOAD_ARCHIVE [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file_ingame.zip"]
#define MOD_DOWNLOAD_PATCH [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_download_file_ingame_patch.mdpatch"]
#define MAPS_DIRECTORY [[applicationSupportPath() stringByAppendingPathComponent:@"GameData"]stringByAppendingPathComponent:@"Maps"]
#define HALO_NEWLINE_CHAR '\x0D'

@implementation ZZTMapDownloader

@synthesize mapIdentifier = _mapIdentifier;
@synthesize mapHumanReadableName = _mapHumanReadableName;
@synthesize patchToMap = _patchToMap;
@synthesize activeDownload = _activeDownload;
@synthesize modList = _modList;
@synthesize mapMd5 = _mapMd5;

static NSString *applicationSupportPath()
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HaloMD"];
}

static void *(*haloprintf)(ConsoleColor color, const char *message, ...) = (void *)0x1588a8;
static void *(*runCommand)(const char *command,const char *error_result, const char *command_name) = (void *)0x11e3de;

typedef enum {
    DOWNLOADING_PATCH,
    DOWNLOADING_ZIP,
    DOWNLOADING_PLUGIN //unsupported right now.
} DownloadType;

static ZZTMapDownloader *self1; //the class is also a download delegate.
static unichar *downloadMessage; //the message we're using to override the error.
static uint32_t *downloadMessageLength; //pointer to message length.
static unichar *error_old; //pointer to the old error, in case we cancel
static void *error_old_location; //the location of the pointer to error text. if we cancel, we can revert it to error_old
static unichar *attention_old; //we're replacing "ATTENTION" with "DOWNLOAD". this is a pointer to "ATTENTION"
static void *attention_old_location; //location of the attention pointer. if we cancel, we can revert it to attention_old
static unichar *ok_old; //we're replacing OK with CANCEL. this is the pointer to "OK"
static void *ok_old_location; //the location of the "OK" text pointer, so if we cancel, we can revert it to ok_old.
static bool downloading = false;
static DownloadType downloadType;

static int unistrlen(unichar *chars) //Halo wants the length of the string. this is a cheap way of finding it.
{
    int length = 0;
    if(chars == NULL) return length;
    
    while(chars[length] != 0x0000)
        length++;
    
    return length;
}
static void changeDownloadMessage(NSString *message) { //changes the message. we use [NSString stringWithFormat:] a lot.
    if(downloadMessage == NULL) return; //if it ever came to this.
    unichar *ustr = (unichar *)[message cStringUsingEncoding:NSUTF16LittleEndianStringEncoding]; //convert to something Halo understands
    uint32_t length = unistrlen(ustr) * 0x2 + 0x2; //Halo will always assume last character is null, even if it isn't. workaround.
    memcpy(downloadMessage,ustr,length); //copy the message to the buffer.
    *(downloadMessageLength) = length; //change message length
}
static void changeError() { //changing the error dialog box.
    @autoreleasepool {
        void *tagArray = (void *)*(uint32_t *)(0x40440000); //location of our tag array. same as Halo PC.
        uint32_t numberOfTags = *(uint32_t *)(0x4044000C);
        for(uint32_t i=0;i<numberOfTags;i++) { //that's where our number of tags is.
            void *location = i*0x20 + tagArray;
            if(strncmp(location,"rtsu",4) == 0 && strcmp((void *)*(uint32_t *)(location + 16),"ui\\shell\\strings\\displayed_error_messages") == 0) {
                free(downloadMessage);
                downloadMessage = calloc(0x100,0x1);
                struct unicodeStringTag *tag = (void *)*(uint32_t *)(location + 20);
                downloadMessageLength = &(tag->references[35].length);
                error_old = tag->references[35].string;
                error_old_location = &(tag->references[35].string);
                tag->references[35].string = downloadMessage;
            } else if(strncmp(location,"rtsu",4) == 0 && strcmp((void *)*(uint32_t *)(location + 16),"ui\\shell\\strings\\common_button_captions") == 0) {
                struct unicodeStringTag *tag = (void *)*(uint32_t *)(location + 20); //tag data, tag data. I want to read my tag data, I want to read my tag!
                tag->references[1].length = tag->references[2].length;
                ok_old = tag->references[1].string;
                ok_old_location = &(tag->references[1].string);
                tag->references[1].string = tag->references[2].string;
            } else if(strncmp(location,"rtsu",4) == 0 && strcmp((void *)*(uint32_t *)(location + 16),"ui\\shell\\error\\error_headers") == 0) {
                struct unicodeStringTag *tag = (void *)*(uint32_t *)(location + 20);
                unichar *downloadHeaderTemp = (unichar *)[@"DOWNLOAD" cStringUsingEncoding:NSUTF16LittleEndianStringEncoding];
                static unichar *downloadHeader;
                free(downloadHeader);
                downloadHeader = calloc(unistrlen(downloadHeaderTemp) * 0x2 + 0x2,0x1);
                memcpy(downloadHeader,downloadHeaderTemp,unistrlen(downloadHeaderTemp) * 0x2 + 0x2);
                attention_old = tag->references[0].string;
                attention_old_location = &(tag->references[0].string);
                tag->references[0].string = downloadHeader;
            }
        }
    }
}
static void cleanup() { //clean up!
    *(uint32_t *)(ok_old_location) = (uint32_t)ok_old;
    *(uint32_t *)(attention_old_location) = (uint32_t)attention_old;
    *(uint32_t *)(error_old_location) = (uint32_t)error_old;
}
static NSString *md5HashFromFilePath(NSString *filePath)
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        haloprintf(NONE,"Attempted to search for %s failed.",[filePath UTF8String]);
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    unsigned char *result = calloc(CC_MD5_DIGEST_LENGTH, 1);
    CC_MD5([data bytes], (unsigned int)[data length], result);
    
    NSMutableString *hash = [NSMutableString string];
    for (int hashIndex = 0; hashIndex < CC_MD5_DIGEST_LENGTH; hashIndex++)
    {
        [hash appendFormat:@"%02x", result[hashIndex]];
    }
    free(result);
    
    return [[hash copy] autorelease];
}
static void *(*haloMapLoadOld)(char *a, uint32_t b, char *c) = NULL;

static void *haloMapLoading(char *a, uint32_t b, char *c) {
    @autoreleasepool {
        if(b == 0x3a98 && !downloading) { // when trying to connect to a server
            char *mapName = (char *)0x3D7B35;
            if(pathToMap([[NSString stringWithCString:mapName encoding:NSUTF8StringEncoding]stringByAppendingPathExtension:@"map"]) != nil) return haloMapLoadOld(a,b,c);
            self1.mapIdentifier = [NSString stringWithCString:mapName encoding:NSUTF8StringEncoding];
            downloadType = DOWNLOADING_ZIP;
            NSURL *patchURL;
            for(NSDictionary *dict in [self1.modList objectForKey:@"Mods"])
            {
                if([[dict objectForKey:@"identifier"] isEqualToString:self1.mapIdentifier]) {
                    self1.mapMd5 = [dict objectForKey:@"hash"];
                    if([dict objectForKey:@"patches"] != nil) {
                        for(NSDictionary *patch in [dict objectForKey:@"patches"]) {
                            NSString *map_path = pathToMap([[patch objectForKey:@"base_identifier"]stringByAppendingPathExtension:@"map"]);
                            if(map_path != nil) {
                                if([md5HashFromFilePath(map_path) isEqualToString:[patch objectForKey:@"base_hash"]]) {
                                    patchURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%@",[patch objectForKey:@"path"]]];
                                    self1.patchToMap = [patch objectForKey:@"base_identifier"];
                                    downloadType = DOWNLOADING_PATCH;
                                    break;
                                }
                            }
                        }
                    }
                    break;
                }
            }
            if(downloadType == DOWNLOADING_PATCH) {
                NSURLRequest *request = [NSURLRequest requestWithURL:patchURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                self1.activeDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self1];
                [self1.activeDownload setDestination:MOD_DOWNLOAD_PATCH allowOverwrite:YES];
            }
            else {
                NSURL *downloadurl = [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%s.zip",mapName]];
                NSURLRequest *request = [NSURLRequest requestWithURL:downloadurl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                self1.activeDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self1];
                [self1.activeDownload setDestination:MOD_DOWNLOAD_ARCHIVE allowOverwrite:YES];
            }
        }
    }
    
    return haloMapLoadOld(a,b,c);
}
typedef enum {
    GAME = 0x20,
    USER = 0x32
} WidgetChangedMeans;

static int (*widgetChangedOld)(int actionsomething, char *action_label, int alwayszero, WidgetChangedMeans means) = NULL;
static int widgetChangedOverride(int actionsomething, char *action_label, int alwayszero, WidgetChangedMeans means) {
    const char forward_label[] = "forward1";
    const char back_label[] = "back1";
    if(means == USER && (strncmp(action_label,forward_label,sizeof forward_label) == 0 || strncmp(action_label,back_label,sizeof back_label) == 0) && downloading) {
        downloading = false;
        cleanup();
        @autoreleasepool {
            [self1.activeDownload cancel];
        }
    }
    return widgetChangedOld(actionsomething,action_label,alwayszero,means);
}
- (id)initWithMode:(MDPluginMode)mode
{
    self = [super init];
    if (self != nil)
    {
        self.modList = dictionaryFromPathWithoutExtension([applicationSupportPath() stringByAppendingPathComponent:@"HaloMD_mods_list"]);
        mach_override_ptr((void *)0x1b5bd6, haloMapLoading, (void **)&haloMapLoadOld);
        mach_override_ptr((void *)0x24bf92, widgetChangedOverride, (void **)&widgetChangedOld);
        self1 = self;
    }
    return self;
}
- (NSBundle *)getBundle {
    return [NSBundle bundleWithIdentifier:@"me.zero2.MapDownloader"];
}
uint32_t fileSize;
uint32_t currentSize;
- (void) downloadDidBegin:(NSURLDownload *)download
{
    if(!downloading) { //Fresh download, rather than a failed patch.
        downloading = true;
        currentSize = 0;
        changeError();
        changeDownloadMessage(@"Download started...");
    }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    //haloprintf(RED,"Map download failed.");
    changeDownloadMessage(@"Download failed!");
}
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    if(currentSize != 0) return; //don't want to reset anything.
    @autoreleasepool {
        fileSize = (uint32_t)[response expectedContentLength];
        self.mapHumanReadableName = self.mapIdentifier;
        NSArray *mods = [self.modList objectForKey:@"Mods"];
        for(NSDictionary *mod in mods) {
            if([[mod objectForKey:@"identifier"] isEqualToString:self.mapIdentifier])
            {
                self.mapHumanReadableName = [mod objectForKey:@"name"];
                break;
            }
        }
        currentSize = 0;
    }
}
- (void) download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    @autoreleasepool {
        if(!downloading) {
            [download cancel];
            return;
        }
        currentSize += length;
        changeDownloadMessage([NSString stringWithFormat:@"Map: %@|nProgress: %.00f%%",self.mapHumanReadableName, fileSize == 0 ? 0 : ((float)currentSize/(float)fileSize*100.0)]);
    }
}
- (void) downloadDidFinish:(NSURLDownload *)download
{
    @autoreleasepool {
        if (downloading == false) {
            cleanup();
            return;
        }
        downloading = false;
        NSString *finalLocationOfMap = [[MAPS_DIRECTORY stringByAppendingPathComponent:self.mapIdentifier] stringByAppendingPathExtension:@"map"];
        if (downloadType == DOWNLOADING_ZIP)
        {
            NSString *unzipDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HaloMD_Unzip_Ingame"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:unzipDirectory])
            {
                [[NSFileManager defaultManager] removeItemAtPath:unzipDirectory error:nil];
            }
            if ([[NSFileManager defaultManager] createDirectoryAtPath:unzipDirectory withIntermediateDirectories:NO attributes:nil error:nil])
            {
                unzFile file = unzOpen([MOD_DOWNLOAD_ARCHIVE UTF8String]);
                unzLocateFile(file, [[self.mapIdentifier stringByAppendingPathExtension:@"map"]UTF8String], 0);
                unzOpenCurrentFile(file);
                unz_file_info *finfo = calloc(sizeof(unz_file_info),0x1);
                uint32_t fileNameBufferSize = [self.mapIdentifier length];
                char *fileName = calloc(fileNameBufferSize,0x1);
                char *extraField = calloc(0x200,0x1);
                uint32_t extraFieldSize = 0x200;
                char *comment = calloc(0x200,0x1);
                uint32_t commentBufferSize = 0x200;
                unzGetCurrentFileInfo(file, finfo, fileName, fileNameBufferSize, extraField, extraFieldSize, comment, commentBufferSize);
                uint32_t mapSize = finfo->uncompressed_size;
                char *mapData = calloc(mapSize, 0x1);
                unzReadCurrentFile(file, mapData, mapSize);
                NSData *data = [NSData dataWithBytes:mapData length:mapSize];
                [data writeToFile:finalLocationOfMap atomically:NO];

                free(fileName);
                free(extraField);
                free(comment);
                free(mapData);

                if(self.mapMd5 != nil && ![self.mapMd5 isEqualToString:md5HashFromFilePath(finalLocationOfMap)]) {
                    changeDownloadMessage(@"Corrupted download. Failed!");
                    return;
                }
            }
        } else if (downloadType == DOWNLOADING_PATCH)
        {
            NSString *patchMapPath = [[MAPS_DIRECTORY stringByAppendingPathComponent:self.patchToMap]stringByAppendingPathExtension:@"map"];
            const char * argv[] = { "bspatch" , [patchMapPath UTF8String], [[[MAPS_DIRECTORY stringByAppendingPathComponent:self.mapIdentifier] stringByAppendingPathExtension:@"map"] UTF8String], [MOD_DOWNLOAD_PATCH UTF8String] };
            if(bspatch_main(4, (char **)argv) != 0 || (self.mapMd5 != nil && ![md5HashFromFilePath([[MAPS_DIRECTORY stringByAppendingPathComponent:self.mapIdentifier] stringByAppendingPathExtension:@"map"]) isEqualToString:self.mapMd5])) {
                changeDownloadMessage(@"Patch failed.|nTrying archive. Hold tight!");
                [[NSFileManager defaultManager] removeItemAtPath:finalLocationOfMap error:nil];
                NSURL *downloadurl = [NSURL URLWithString:[NSString stringWithFormat:@"http://halomd.macgamingmods.com/mods/%s.zip",[self.mapIdentifier UTF8String]]];
                NSURLRequest *request = [NSURLRequest requestWithURL:downloadurl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                self.activeDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self1];
                [self.activeDownload setDestination:MOD_DOWNLOAD_ARCHIVE allowOverwrite:YES];
                return;
            }
        }
        [self rejoinServerAndCleanup];
    }
}
- (void) rejoinServerAndCleanup {
    @autoreleasepool {
        NSString *ip = [NSString stringWithFormat:@"%u.%u.%u.%u:%u",*(uint8_t*)(0x466054+3),*(uint8_t*)(0x466054+2),*(uint8_t*)(0x466054+1),*(uint8_t*)(0x466054+0),*(uint16_t*)(0x466066)];
        NSString *password = [[NSString alloc]initWithCharacters:(unichar *)0x466090 length:unistrlen((unichar *)0x466090)];
        NSString *connect = [NSString stringWithFormat:@"connect %@ \"%@\"",ip,password];
        //haloprintf(NONE,"%s",[connect UTF8String]);
        runCommand([connect cStringUsingEncoding:NSISOLatin1StringEncoding],"Failed to rejoin server with %s.","connect");
        downloading = false;
    }
}
static NSString *pathToMap(NSString *map)
{
    NSString *mapPath = [[[[[NSProcessInfo processInfo] environment] objectForKey:@"MD_STOCK_GAME_DATA_DIRECTORY"]stringByAppendingPathComponent:@"Maps"] stringByAppendingPathComponent:map]; //Check HaloMD bundle
    if([[NSFileManager defaultManager] fileExistsAtPath:mapPath]) return mapPath;
    mapPath = [MAPS_DIRECTORY stringByAppendingPathComponent:map]; //Check maps folder
    if([[NSFileManager defaultManager] fileExistsAtPath:mapPath]) return mapPath;
    return nil;
}
static NSDictionary *dictionaryFromPathWithoutExtension(NSString *pathWithoutExtension)
{
    NSDictionary *modsDictionary = nil;
    BOOL jsonSerializationExists = NSClassFromString(@"NSJSONSerialization") != nil;
    
    NSString *fileExtension = jsonSerializationExists ? @"json" : @"plist";
    NSString *fullPath = [pathWithoutExtension stringByAppendingPathExtension:fileExtension];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
        if (!jsonSerializationExists)
        {
            modsDictionary = [NSDictionary dictionaryWithContentsOfFile:fullPath];
            if (modsDictionary == nil)
            {
                NSLog(@"Failed decoding plist at %@", fullPath);
            }
        }
        else
        {
            NSData *jsonData = [NSData dataWithContentsOfFile:fullPath];
            if (jsonData != nil)
            {
                NSError *error = nil;
                modsDictionary = [NSClassFromString(@"NSJSONSerialization") JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
                if (error != nil)
                {
                    NSLog(@"Failed decoding JSON: %@", error);
                }
            }
        }
    }
    
    return modsDictionary;
}

- (void)mapDidBegin:(NSString *)mapName {
}
- (void)mapDidEnd:(NSString *)mapName {
}
@end
