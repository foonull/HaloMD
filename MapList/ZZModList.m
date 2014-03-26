/*
 * Copyright (c) 2013, Zero2
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this
 * list of conditions and the following disclaimer in the documentation and/or
 * other materials provided with the distribution.
 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  ZZModList.m
//  ModList
//
//  Created by Paul Whitcomb on 11/23/13.
//  Copyright (c) 2013 Zero2. All rights reserved.
//

#import "ZZModList.h"
#import "mach_override.h"

#define SET_HALO_MAPS_COUNT(value) (*(uint32_t *)(0x3D2D84) = value)

@implementation ZZModList

static NSMutableArray *gMapsAdded;
static NSDictionary *gModsList;

static NSString *applicationSupportPath(void)
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HaloMD"];
}

static NSString *mapsDirectory(void)
{
    return [[applicationSupportPath() stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
}

static int buildNumberFromIdentifier(NSString *mapIdentifier) //straight from HaloMD's source
{
    int buildNumber = 0;
    
    NSRange range = [mapIdentifier rangeOfString:@"_" options:NSBackwardsSearch];
    if (range.location != NSNotFound)
    {
        if (range.location+1 < [mapIdentifier length])
        {
            NSString *identifierNumber = [mapIdentifier substringFromIndex:range.location+1];
            if ([[[NSNumber numberWithInteger:[identifierNumber intValue]] stringValue] isEqualToString:identifierNumber])
            {
                buildNumber = [identifierNumber intValue];
            }
        }
    }
    
    return buildNumber;
}

static NSString *mapIdentityFromIdentifier(NSString *mapIdentifier)
{
    if (buildNumberFromIdentifier(mapIdentifier) == 0) return mapIdentifier;

    NSString *mapName = mapIdentifier;
    NSRange range = [mapIdentifier rangeOfString:@"_" options:NSBackwardsSearch];
    if (range.location != NSNotFound)
    {
        if (range.location+1 < [mapIdentifier length])
        {
            mapName = [mapIdentifier substringToIndex:range.location];
        }
    }
    return mapName;
}

static BOOL hideMapBecauseOutdated(NSString *map) { //hide map if a later version of the map is available
    if(!mapIsOutdated(map)) return NO;

    int buildNumber = buildNumberFromIdentifier(map);
    NSString *name = mapNameFromIdentifier(map);
    NSArray *files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:mapsDirectory() error:nil];
    for (NSUInteger i=0; i<[files count]; i++) {
        NSString *file = [files objectAtIndex:i];
        if ([[file pathExtension] isEqualToString:@"map"]) {
                NSString *fileWithoutExtension = [[file lastPathComponent] stringByDeletingPathExtension];
                if(![mapNameFromIdentifier(name) isEqualToString:mapNameFromIdentifier(fileWithoutExtension)])
                    continue;
                if(buildNumberFromIdentifier(fileWithoutExtension) > buildNumber)
                    return YES;
        }
    }
    return NO;
}

static BOOL mapIsOutdated(NSString *map) { //check if there is a newer version of the map
    NSString *mapName = mapNameFromIdentifier(map);
    int buildNumber = buildNumberFromIdentifier(map);

    if(gModsList == nil || buildNumber == 0) return NO;

    if([mapName isEqualToString:map]) return NO;

    NSArray *arrayMods = [gModsList objectForKey:@"Mods"];
    for (NSUInteger i=0; i < [arrayMods count]; i++) {
        if ([[[arrayMods objectAtIndex:i] objectForKey:@"name"] isEqualToString:mapName]) {
            if (buildNumberFromIdentifier([[arrayMods objectAtIndex:i] objectForKey:@"identifier"]) > buildNumber) {
                return YES;
            }
        }
    }
    return NO;
}

static NSString *stockMapName(NSString *map) { //hardcode human names of stock maps and FV maps
    if([map isEqualToString:@"beavercreek"])
        return @"Battle Creek";
    else if([map isEqualToString:@"boardingaction"])
        return @"Boarding Action";
    else if([map isEqualToString:@"carousel"])
        return @"Derelict";
    else if([map isEqualToString:@"chillout"])
        return @"Chill Out";
    else if([map isEqualToString:@"damnation"])
        return @"Damnation";
    else if([map isEqualToString:@"dangercanyon"])
        return @"Danger Canyon";
    else if([map isEqualToString:@"deathisland"])
        return @"Death Island";
    else if([map isEqualToString:@"gephyrophobia"])
        return @"Gephyrophobia";
    else if([map isEqualToString:@"hangemhigh"])
        return @"Hang 'Em High";
    else if([map isEqualToString:@"icefields"])
        return @"Ice Fields";
    else if([map isEqualToString:@"infinity"])
        return @"Infinity";
    else if([map isEqualToString:@"longest"])
        return @"Longest";
    else if([map isEqualToString:@"prisoner"])
        return @"Prisoner";
    else if([map isEqualToString:@"putput"]) //I can never understand why they
        return @"Chiron TL34";               //named it putput instead of chiron
    else if([map isEqualToString:@"ratrace"])
        return @"Rat Race";
    else if([map isEqualToString:@"sidewinder"])
        return @"Sidewinder";
    else if([map isEqualToString:@"timberland"])
        return @"Timberland";
    else if([map isEqualToString:@"wizard"])
        return @"Wizard";
    else if([map isEqualToString:@"crossing"])
        return @"Crossing";
    else if([map isEqualToString:@"barrier"])
        return @"Barrier";
    else if([map isEqualToString:@"bloodgulch"])
        return @"Blood Gulch";
    else
        return map;
}

static NSString *mapNameFromIdentifier(NSString *identifier) {
    if (gModsList == nil) return identifier;

    NSArray *arrayMods = [gModsList objectForKey:@"Mods"];
    for (NSDictionary *mod in arrayMods) {
        if ([[mod objectForKey:@"identifier"] isEqualToString:identifier]) {
            return [mod objectForKey:@"name"];
        }
    }

    return stockMapName(identifier);
}

static NSString *mapDescriptionFromIdentifier(NSString *identifier) {
    if([identifier isEqualToString:@"crossing"])
        return @"A Memorial|nto Heroes Fallen";
    else if([identifier isEqualToString:@"barrier"])
        return @"So Close,|nYet So Far..";
    else if([identifier isEqualToString:@"bloodgulch"])
        return @"The Quick|nand the Dead"; //we already know it supports vehicles

    if(gModsList == nil) return @"N/A";

    NSArray *arrayMods = [gModsList objectForKey:@"Mods"];
    for (NSDictionary *mod in arrayMods) {
        if ([[mod objectForKey:@"identifier"] isEqualToString:identifier]) {
            return [NSString stringWithFormat:@"File: %@|nVersion: %@|n|n%@",
                    [mod objectForKey:@"identifier"],
                    [mod objectForKey:@"human_version"],
                    mapIsOutdated(identifier) ? @"Outdated Map!|nRedownload on|nHaloMD to update." : @"Latest version"];
            //give instructions on how to update the map if it's outdated
        }
    }

    NSString *stockMap = stockMapName(identifier);
    return [NSString stringWithFormat:@"File: %@|n%@",
            identifier,
            [stockMap isEqualToString:identifier] ? @"Custom map" : @"Retail Halo map"];
}

static void changeMapEntry(MapListEntry **mapsPointer, char *desiredMap, int tableIndex)
{
    char *mapName = calloc(strlen(desiredMap),1); //map needs to be allocated, or else Halo hates it
    memcpy(mapName,desiredMap,strlen(desiredMap));
    (*mapsPointer)[tableIndex].name = mapName;
    (*mapsPointer)[tableIndex].enabled = 1;
    (*mapsPointer)[tableIndex].index = tableIndex;
}

static void refreshMaps(NSMutableArray *mapsAdded) { //remake the map array
    static MapListEntry *newMaps;
    static MapListEntry **mapsPointer = (void *)0x3691c0;

    if (newMaps != NULL) {
        for(uint32_t i = 0;i < [mapsAdded count]; i++) {
            free(newMaps[i].name);
        }
    }
    [mapsAdded removeAllObjects];

    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mapsDirectory() error:NULL];
    for(NSUInteger i = 0; i < [files count]; i++) {
        NSString *file = [files objectAtIndex:i];
        if ([[file pathExtension] isEqualToString:@"map"]) {
            NSString *fileWithoutExtension = [[file lastPathComponent] stringByDeletingPathExtension];
            if (![stockMapName(fileWithoutExtension) isEqualToString:fileWithoutExtension] ||(buildNumberFromIdentifier(fileWithoutExtension) > 0 && !hideMapBecauseOutdated(fileWithoutExtension))) {
                [mapsAdded addObject:fileWithoutExtension];
            }
        }
    }

    uint32_t mapsCount = [mapsAdded count];
    SET_HALO_MAPS_COUNT(mapsCount); //we need to override map count or else the 18 map limit remover died in vain
    newMaps = malloc(sizeof(MapListEntry) * (mapsCount));
    *mapsPointer = newMaps;
    [mapsAdded sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for(uint32_t i = 0; i < mapsCount; i++) {
        changeMapEntry(mapsPointer, (char *)[[mapsAdded objectAtIndex:i] UTF8String], i);
    }
}

#define HALO_INDEX_LOCATION 0x40440000 //same on Halo PC and CE
#define TAG_COUNT_OFFSET 0xC
#define TAG_MAP_NAMES "ui\\shell\\main_menu\\mp_map_list"
#define TAG_MAP_DESCRIPTIONS "ui\\shell\\main_menu\\multiplayer_type_select\\mp_map_select\\map_data"
#define TAG_MAP_ICONS "ui\\shell\\bitmaps\\mp_map_grafix"

typedef enum {
    BARRIER_OFFSET = 0xD71630,
    BLOODGULCH_OFFSET = 0xD75630,
    CROSSING_OFFSET = 0xD91630,
    GENERIC_OFFSET = 0xDA1630 //? icon
} MapIconOffsets;

static void replaceUstr(NSMutableArray *mapsAdded) { //refreshes map names and descriptions - required on map load
    static struct unicodeStringReference *referencesMapName;
    static uint32_t referencesMapNameCount;

    static struct unicodeStringReference *referencesMapDesc;
    static uint32_t referencesMapDescCount;

    static struct bitmapBitmap *mapPicturesBitmaps;

    uint32_t mapsCount = [mapsAdded count];
    
    MapTag *tagArray = (MapTag *)*(uint32_t *)(HALO_INDEX_LOCATION);
    uint32_t numberOfTags = *(uint32_t *)(HALO_INDEX_LOCATION + TAG_COUNT_OFFSET);
    
    for(uint32_t i = 0; i < numberOfTags; i++) {
        if (tagArray[i].classA == *(uint32_t *)&"rtsu") {
            struct unicodeStringReference **mapReference = NULL;
            uint32_t *mapCountReference = NULL;
            NSString *(*mapStringFunction)(NSString *) = NULL;

            if (strcmp(tagArray[i].nameOffset,TAG_MAP_NAMES) == 0) {
                mapReference = &referencesMapName;
                mapCountReference = &referencesMapNameCount;
                mapStringFunction = mapNameFromIdentifier;
            }
            else if (strcmp(tagArray[i].nameOffset,TAG_MAP_DESCRIPTIONS) == 0) {
                mapReference = &referencesMapDesc;
                mapCountReference = &referencesMapDescCount;
                mapStringFunction = mapDescriptionFromIdentifier;
            }

            if (mapReference != NULL && mapCountReference != NULL && mapStringFunction != NULL) {
                for (uint32_t q = 0; q < *mapCountReference; q++) {
                    free((*mapReference)[q].string);
                }
                free(*mapReference);

                struct unicodeStringTag *tag = tagArray[i].dataOffset;
                tag->referencesCount = mapsCount;
                *mapReference = malloc(mapsCount * sizeof(**mapReference));
                tag->references = *mapReference;
                *mapCountReference = mapsCount;

                for (uint32_t q = 0; q < mapsCount; q++) {
                    NSString *mapString = mapStringFunction([mapsAdded objectAtIndex:q]);
                    uint32_t length = sizeof(unichar) * ([mapString length]+1);
                    (*mapReference)[q].length = length;

                    unichar *newMapString = calloc(length,1); //allocate or else a disaster beyond your imagination will occur
                    memcpy(newMapString,[mapString cStringUsingEncoding:NSUTF16LittleEndianStringEncoding],length);
                    (*mapReference)[q].string = newMapString;
                }
            }
        }
        else if(tagArray[i].classA == *(uint32_t *)&"mtib" && strcmp(tagArray[i].nameOffset,TAG_MAP_ICONS) == 0) {
            free(mapPicturesBitmaps);
            mapPicturesBitmaps = calloc(sizeof(*mapPicturesBitmaps), mapsCount);
            struct bitmapTag *tag = tagArray[i].dataOffset;

            for(uint32_t i = 0; i < mapsCount; i++) {
                mapPicturesBitmaps[i].bitmapSignature = *(uint32_t *)&"mtib";
                mapPicturesBitmaps[i].width = 256;
                mapPicturesBitmaps[i].height = 128;
                mapPicturesBitmaps[i].depth = 1;
                mapPicturesBitmaps[i].format = 14;
                mapPicturesBitmaps[i].flags = 0x183;
                mapPicturesBitmaps[i].x = 128;
                mapPicturesBitmaps[i].y = 90;
                mapPicturesBitmaps[i].pixelOffset = GENERIC_OFFSET;
                mapPicturesBitmaps[i].pixelCount = 16384;
                mapPicturesBitmaps[i].bitmapLoneID = tagArray[i].identity;
                mapPicturesBitmaps[i].ffffffff = -1;
            }

            mapPicturesBitmaps[[mapsAdded indexOfObject:@"bloodgulch"]].pixelOffset = BLOODGULCH_OFFSET;
            mapPicturesBitmaps[[mapsAdded indexOfObject:@"crossing"]].pixelOffset = CROSSING_OFFSET;
            mapPicturesBitmaps[[mapsAdded indexOfObject:@"barrier"]].pixelOffset = BARRIER_OFFSET;
            tag->bitmap = mapPicturesBitmaps;
            tag->bitmapsCount = mapsCount;
            for (uint32_t i = 0; i < tag->sequenceCount; i++) {
                tag->sequence[i].finalIndex = mapsCount;
            }
        }
    }
}

- (void)mapDidBegin:(NSString *)mapName
{
    refreshMaps(gMapsAdded);
    replaceUstr(gMapsAdded);
}

- (void)mapDidEnd:(NSString *)mapName
{
}

static NSDictionary *dictionaryFromPathWithoutExtension(NSString *pathWithoutExtension) //taken from HaloMD
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
                NSLog(@"Map Downloader Failed decoding plist at %@", fullPath);
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
                    NSLog(@"Map Downloader Failed decoding JSON: %@", error);
                }
            }
        }
    }
    
    return modsDictionary;
}
static void (*runCommand)(char *command,char *error_result,char *command_name) = NULL;
static void interceptCommand(char *command,char *error_result, char *command_name)
{
    if (strcmp(command_name,"sv_map") == 0) {
        @autoreleasepool {
            NSMutableArray *args = [[[[NSString stringWithCString:command encoding:NSUTF8StringEncoding] componentsSeparatedByString:@" "] mutableCopy] autorelease];
            if ([args count] >= 2) {
                NSString *map = [args objectAtIndex:1];
                if (![gMapsAdded containsObject:map] && [mapIdentityFromIdentifier(map) isEqualToString:map]) {
                    NSString *bestMap = map;
                    for (NSString *mapSearched in gMapsAdded) {
                        if ([mapIdentityFromIdentifier(mapSearched) isEqualToString:map] && buildNumberFromIdentifier(mapSearched) > buildNumberFromIdentifier(map)) {
                            bestMap = mapSearched;
                        }
                    }
                    [args setObject:bestMap atIndexedSubscript:1];
                    return runCommand((char *)[[args componentsJoinedByString:@" "] UTF8String],error_result,command_name);
                }
            }
        }
    }
    return runCommand(command,error_result,command_name);
}

- (id)initWithMode:(MDPluginMode)mode
{
    self = [super init];
    if (self != nil)
    {
        gMapsAdded = [[NSMutableArray alloc] init];
        gModsList = [dictionaryFromPathWithoutExtension([applicationSupportPath() stringByAppendingPathComponent:@"HaloMD_mods_list"]) retain];
        
        mach_override_ptr((void *)0x11e3de, interceptCommand, (void **)&runCommand);
        
        void *mapLimitInstructions = (void *)0x1558D6; //deleting the 18 map limit
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_WRITE);
        memset(mapLimitInstructions,0x90,5);
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_EXEC);
    }
    return self;
}

@end
