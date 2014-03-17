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

#define MAPS_DIRECTORY [[applicationSupportPath() stringByAppendingPathComponent:@"GameData"]stringByAppendingPathComponent:@"Maps"]
#define HALO_MAPS_COUNT *(uint32_t *)(0x3D2D84)

@implementation ZZModList

NSMutableArray *mapsAdded;
NSDictionary *modsList;

bool loaded = false;

static NSString *applicationSupportPath()
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HaloMD"];
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
            if([[[NSNumber numberWithInteger:[identifierNumber intValue]]stringValue] isEqualToString:identifierNumber])
                buildNumber = [identifierNumber intValue];
        }
    }
    
    return buildNumber;
}

static NSString *mapIdentityFromIdentifier(NSString *mapIdentifier)
{
    if(buildNumberFromIdentifier(mapIdentifier) == 0) return mapIdentifier;
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

static bool hideMapBecauseOutdated(NSString *map) { //hide map if a later version of the map is available
    if(!mapIsOutdated(map)) return NO;
    int buildNumber = buildNumberFromIdentifier(map);
    NSString *name = mapNameFromIdentifier(map);
    NSError *error = [[NSError alloc]init];
    NSArray *files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:MAPS_DIRECTORY error:&error];
    for(NSUInteger i=0;i<[files count];i++) {
        NSString *file = [files objectAtIndex:i];
        if([file hasSuffix:@".map"]) {
            @autoreleasepool {
                NSString *fileWithoutExtension = [[file lastPathComponent]stringByDeletingPathExtension];
                if(![mapNameFromIdentifier(name) isEqualToString:mapNameFromIdentifier(fileWithoutExtension)])
                    continue;
                if(buildNumberFromIdentifier(fileWithoutExtension) > buildNumber)
                    return YES;
            }
        }
    }
    return NO;
}

static bool mapIsOutdated(NSString *map) { //check if there is a newer version of the map
    @autoreleasepool {
        NSString *mapName = mapNameFromIdentifier(map);
        int buildNumber = buildNumberFromIdentifier(map);
        if(modsList == nil || buildNumber == 0) return NO;
        if([mapName isEqualToString:map]) return NO;
        NSArray *arrayMods = [modsList objectForKey:@"Mods"];
        for(NSUInteger i=0;i<[arrayMods count];i++) {
            if([[[arrayMods objectAtIndex:i]objectForKey:@"name"] isEqualToString:mapName]) {
                if(buildNumberFromIdentifier([[arrayMods objectAtIndex:i]objectForKey:@"identifier"]) > buildNumber) return YES;
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
        return @"voidDangercanyon";
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
    if(modsList == nil) return identifier;
    NSArray *arrayMods = [modsList objectForKey:@"Mods"];
    for(NSDictionary *mod in arrayMods) {
        if([[mod objectForKey:@"identifier"] isEqualToString:identifier]) {
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
    if(modsList == nil) return @"N/A";
    NSArray *arrayMods = [modsList objectForKey:@"Mods"];
    for(NSDictionary *mod in arrayMods) {
        if([[mod objectForKey:@"identifier"] isEqualToString:identifier]) {
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

struct unicodeStringReference *referencesMapName = NULL;
uint32_t referencesMapNameCount;

struct unicodeStringReference *referencesMapDesc = NULL;
uint32_t referencesMapDescCount;

struct bitmapBitmap *mapPicturesBitmaps = NULL;
uint32_t bitmapsCount;

MapListEntry **mapsPointer = (void *)0x3691c0;
MapListEntry *newMaps = NULL;

static void changeMapEntry(char *desiredMap, int tableIndex)
{
    char *mapName = calloc(strlen(desiredMap),1); //map needs to be allocated, or else Halo hates it
    memcpy(mapName,desiredMap,strlen(desiredMap));
    (*mapsPointer)[tableIndex].name = mapName;
    (*mapsPointer)[tableIndex].enabled = 1;
    (*mapsPointer)[tableIndex].index = tableIndex;
}

static void refreshMaps(void) { //remake the map array
    if(newMaps != NULL) {
        for(uint32_t i=0;i<[mapsAdded count]-1;i++) {
            free(newMaps[i].name);
        }
    }
    [mapsAdded removeAllObjects];
    NSError *error = [[NSError alloc]init];
    NSArray *files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:MAPS_DIRECTORY error:&error];
    for(NSUInteger i=0;i<[files count];i++) {
        NSString *file = [files objectAtIndex:i];
        if([file hasSuffix:@".map"]) {
            NSString *fileWithoutExtension = [[file lastPathComponent]stringByDeletingPathExtension];
            if(![stockMapName(fileWithoutExtension) isEqualToString:fileWithoutExtension] ||(buildNumberFromIdentifier(fileWithoutExtension) > 0 && !hideMapBecauseOutdated(fileWithoutExtension))) {
                [mapsAdded addObject:fileWithoutExtension];
            }
        }
    }
    uint32_t mapsCount = [mapsAdded count];
    HALO_MAPS_COUNT = mapsCount; //we need to override map count or else the 18 map limit remover died in vain
    newMaps = malloc(sizeof(MapListEntry) * (mapsCount));
    *mapsPointer = newMaps;
    [mapsAdded sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for(uint32_t i=0;i<mapsCount;i++) {
        changeMapEntry((char *)[[mapsAdded objectAtIndex:i]UTF8String], i);
    }
    *mapsPointer = newMaps;
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

static void replaceUstr(void) { //refreshes map names and descriptions - required on map load
    uint32_t count = [mapsAdded count];
    
    MapTag *tagArray = (MapTag *)*(uint32_t *)(HALO_INDEX_LOCATION);
    uint32_t numberOfTags = *(uint32_t *)(HALO_INDEX_LOCATION + TAG_COUNT_OFFSET);
    
    for(uint32_t i=0;i<numberOfTags;i++) {
        if(tagArray[i].classA == *(uint32_t *)&"rtsu" && strcmp(tagArray[i].nameOffset,TAG_MAP_NAMES) == 0) {
            if(referencesMapName != NULL) {
                for(uint32_t q=0;q<referencesMapNameCount;q++) {
                    free(referencesMapName[q].string);
                }
                free(referencesMapName);
            }
            struct unicodeStringTag *tag = tagArray[i].dataOffset;
            tag->referencesCount = count;
            referencesMapName = malloc(count * sizeof(struct unicodeStringReference));
            tag->references = referencesMapName;
            referencesMapNameCount = [mapsAdded count];
            for(uint32_t q=0;q<[mapsAdded count];q++) {
                NSString *map = mapNameFromIdentifier([mapsAdded objectAtIndex:q]);
                uint32_t length = sizeof(unichar) * ([map length]+1);
                referencesMapName[q].length = length;
                unichar *newmap_name = calloc(length,1); //allocate map name or else a disaster beyond your imagination will occur
                memcpy(newmap_name,[map cStringUsingEncoding:NSUTF16LittleEndianStringEncoding],length);
                referencesMapName[q].string = newmap_name;
            }
        }
        else if(tagArray[i].classA == *(uint32_t *)&"rtsu" && strcmp(tagArray[i].nameOffset,TAG_MAP_DESCRIPTIONS) == 0) {
            if(referencesMapDesc != NULL) {
                for(uint32_t q=0;q<referencesMapDescCount;q++) {
                    free(referencesMapDesc[q].string);
                }
                free(referencesMapDesc);
            }
            struct unicodeStringTag *tag = tagArray[i].dataOffset;
            tag->referencesCount = count;
            referencesMapDesc = malloc(count * sizeof(struct unicodeStringReference));
            tag->references = referencesMapDesc;
            referencesMapDescCount = [mapsAdded count];
            for(uint32_t q=0;q<[mapsAdded count];q++) {
                NSString *desc = mapDescriptionFromIdentifier([mapsAdded objectAtIndex:q]);
                uint32_t length = sizeof(unichar) * ([desc length]+1);
                referencesMapDesc[q].length = length;
                unichar *newmap_name = calloc(length,1);
                memcpy(newmap_name,[desc cStringUsingEncoding:NSUTF16LittleEndianStringEncoding],length);
                referencesMapDesc[q].string = newmap_name;
            }
        }
        else if(tagArray[i].classA == *(uint32_t *)&"mtib" && strcmp(tagArray[i].nameOffset,TAG_MAP_ICONS) == 0) {
            if(mapPicturesBitmaps != NULL) free(mapPicturesBitmaps);
            mapPicturesBitmaps = calloc(sizeof(struct bitmapBitmap), count);
            struct bitmapTag *tag = tagArray[i].dataOffset;
            for(uint32_t i=0;i<[mapsAdded count];i++) {
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
            tag->bitmapsCount = count;
            for(uint32_t i=0;i<tag->sequenceCount;i++) {
                tag->sequence[i].finalIndex = [mapsAdded count];
            }
        }
    }
}

- (void)mapDidBegin:(NSString *)mapName
{
    refreshMaps();
    replaceUstr();
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
    if(strcmp(command_name,"sv_map") == 0) {
        @autoreleasepool {
            NSMutableArray *args = [[[NSString stringWithFormat:@"%s",command] componentsSeparatedByString:@" "]mutableCopy];
            if([args count] >= 2) {
                NSString *map = [args objectAtIndex:1];
                if(![mapsAdded containsObject:map] && mapIdentityFromIdentifier(map) == map) {
                    NSString *bestMap = map;
                    for(NSString *mapSearched in mapsAdded) {
                        if([mapIdentityFromIdentifier(mapSearched) isEqualToString:map] && buildNumberFromIdentifier(mapSearched) > buildNumberFromIdentifier(map)) {
                            bestMap = mapSearched;
                        }
                    }
                    [args setObject:bestMap atIndexedSubscript:1];
                    return runCommand((char *)[[args componentsJoinedByString:@" "]UTF8String],error_result,command_name);
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
        mapsAdded = [[NSMutableArray alloc]init];
		modsList = dictionaryFromPathWithoutExtension([applicationSupportPath() stringByAppendingPathComponent:@"HaloMD_mods_list"]);
        [modsList retain];
        mach_override_ptr((void *)0x11e3de, interceptCommand, (void **)&runCommand);
        
        void *mapLimitInstructions = (void *)0x1558D6; //deleting the 18 map limit
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_WRITE);
        memset(mapLimitInstructions,0x90,5);
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_EXEC);
        
	}
	return self;
}

@end
