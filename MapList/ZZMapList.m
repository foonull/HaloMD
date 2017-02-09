/*
 * Copyright (c) 2016, 002
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

#import "ZZMapList.h"
#import "ZZUnicodeStringTag.h"
#import "ZZBitmapsTag.h"
#import "ZZMapData.h"
#import <sys/mman.h>
#import "mach_override.h"

static MapListArray *mp_map_list = NULL;

#define HALO_INDEX_LOCATION 0x40440000 //same on Halo PC and CE
#define TAG_COUNT_OFFSET 0xC
#define TAG_MAP_NAMES "ui\\shell\\main_menu\\mp_map_list"
#define TAG_MAP_DESCRIPTIONS "ui\\shell\\main_menu\\multiplayer_type_select\\mp_map_select\\map_data"
#define TAG_MAP_ICONS "ui\\shell\\bitmaps\\mp_map_grafix"


@implementation ZZMapList

static NSMutableArray *multiplayer_maps = nil;
static BOOL show_outdated_maps = NO;
static BOOL show_all_maps = NO;
static void *(*halo_printf)(void *color, const char *message, ...) = (void *)0x1588a8;
static void (*run_command)(const char *command,const char *errorResult,const char *commandName) = NULL;

/// This function gets the path to HaloMD's application support folder.
static NSString *application_support_path(void)
{
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"HaloMD"];
}

/// This function gets the path to HaloMD's maps directory.
static NSString *maps_directory(void)
{
    return [[application_support_path() stringByAppendingPathComponent:@"GameData"] stringByAppendingPathComponent:@"Maps"];
}

/// Straight from HaloMD's source. This gets the build number out of an identifier.
/// Example:
///     mapname_5           --> 5
///     bestmod_ever_6      --> 6
///     a30                 --> 0
///     amazing_thing_1_2_3 --> 3
static int build_number_from_identifier(NSString *mapIdentifier)
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

/// This function checks if this map file is the latest that is currntly installed.
/// Any mod that is not on the mod list is assumed to be the latest, even if there is a map with the same identifier installed.
static BOOL is_latest_installed(NSString *identifier,NSArray *fileList,NSDictionary *modList) {
    NSDictionary *mod_info = map_data_from_identifier(identifier, modList);
    if(mod_info == nil) return YES;
    NSString *mod_name = [mod_info objectForKey:@"name"];
    int build_number = build_number_from_identifier(identifier);
    for(NSString *i in fileList) {
        NSString *test_identifier = [i stringByDeletingPathExtension];
        int test_build = build_number_from_identifier(test_identifier);
        if([[map_data_from_identifier(test_identifier,modList) objectForKey:@"name"] isEqualToString:mod_name] && test_build > build_number) return NO;
    }
    
    return YES;
}


/// Human names for all of the stock Halo PC maps, or itself if it's not a stock map file.
static NSString *stock_map_name(NSString *map) {
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
    else if([map isEqualToString:@"putput"])
        return @"Chiron TL34";
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

/// Convenience function for getting metadata of a map out of the mod database using an identifier.
static NSDictionary *map_data_from_identifier(NSString *identifier, NSDictionary *modDatabase) {
    for (NSDictionary *mod in [modDatabase objectForKey:@"Mods"]) {
        if ([[mod objectForKey:@"identifier"] isEqualToString:identifier]) {
            return mod;
        }
    }
    return nil;
}

/// This function checks if the map is outdated out of the entire mod database.
/// A map that is not in the database is assumed to be up-to-date.
static BOOL map_is_outdated(NSString *identifier, NSDictionary *modDatabase) {
    NSDictionary *mod = map_data_from_identifier(identifier, modDatabase);
    NSString *mod_name = [mod objectForKey:@"name"];
    if(mod == nil) return NO;
    int version = build_number_from_identifier(identifier);
    for(NSDictionary *mod_search in [modDatabase objectForKey:@"Mods"]) {
        if([[mod_search objectForKey:@"name"]isEqualToString:mod_name] && version < build_number_from_identifier([mod_search objectForKey:@"identifier"])) {
            return YES;
        }
    }
    return NO;
}

/// Generate a bitmap sequence from a set of maps.
static HaloBitmap *generate_map_bitmap_from_array(NSArray *array, uint32_t identity) {
    NSUInteger count = [array count];
    HaloBitmap *b = malloc(sizeof(*b) * count);
    for(uint32_t i=0;i<count;i++) {
        b[i].bitmapSignature = *(uint32_t *)&"mtib";
        b[i].width = 256;
        b[i].height = 128;
        b[i].depth = 1;
        b[i].type = 0;
        b[i].format = 14;
        b[i].flags = 0x183;
        b[i].x = 128;
        b[i].y = 90;
        b[i].mipmap = 0;
        NSString *name = [[array objectAtIndex:i]stringByDeletingPathExtension];
        if([name isEqualToString:@"barrier"]) {
            b[i].pixelOffset = BARRIER_OFFSET;
        }
        else if([name isEqualToString:@"bloodgulch"]) {
            b[i].pixelOffset = BLOODGULCH_OFFSET;
        }
        else if([name isEqualToString:@"crossing"]) {
            b[i].pixelOffset = CROSSING_OFFSET;
        }
        else {
            b[i].pixelOffset = GENERIC_OFFSET;
        }
        b[i].pixelCount = 16384;
        b[i].bitmapLoneID = identity;
        b[i].pointer = 0xFFFFFFFF;
        b[i].zero = 0;
        b[i].unknown = 0;
    }
    return b;
}

/// This generates a USTR tag that can be used to replace the map names USTR tag.
/// This value will have to be freed with free_ustr_tag() at some point to prevent memory leaks.
/// Do NOT free the pointer to the original USTR tag, as it's already being managed by Halo.
static UnicodeStringTag *generate_map_names_from_array(NSArray *array, NSDictionary *modDatabase) {
    UnicodeStringTag *tag = malloc(sizeof(UnicodeStringTag));
    tag->referencesCount = [array count];
    tag->zero = 0;
    tag->references = calloc(sizeof(UnicodeStringReference), tag->referencesCount);
    for(uint32_t i=0;i<tag->referencesCount;i++) {
        NSString *map_name = [[array objectAtIndex:i]stringByDeletingPathExtension];
        NSDictionary *mod = map_data_from_identifier(map_name, modDatabase);
        if(mod != nil) {
            if(show_outdated_maps) {
                map_name = [NSString stringWithFormat:@"%@ %@",[mod objectForKey:@"name"],[mod objectForKey:@"human_version"]];
            }
            else {
                map_name = [mod objectForKey:@"name"];
            }
        }
        else {
            map_name = stock_map_name(map_name);
        }
        
        size_t data_size = sizeof(*tag->references->string) * ([map_name length] + 1);
        tag->references[i].string = calloc(data_size,1);
        memcpy(tag->references[i].string, [map_name cStringUsingEncoding:NSUTF16LittleEndianStringEncoding], data_size);
        tag->references[i].length = data_size;
    }
    return tag;
}

/// This generates a USTR tag that can be used to replace the map descriptions USTR tag.
/// This value will have to be freed with free_ustr_tag() at some point to prevent memory leaks.
/// Do NOT free the pointer to the original USTR tag, as it's already being managed by Halo.
static UnicodeStringTag *generate_map_descriptions_from_array(NSArray *array, NSDictionary *modDatabase) {
    UnicodeStringTag *tag = malloc(sizeof(UnicodeStringTag));
    tag->referencesCount = [array count];
    tag->zero = 0;
    tag->references = calloc(sizeof(UnicodeStringReference), tag->referencesCount);
    for(uint32_t i=0;i<tag->referencesCount;i++) {
        NSString *map_name = [[array objectAtIndex:i]stringByDeletingPathExtension];
        NSDictionary *mod = map_data_from_identifier(map_name, modDatabase);
        NSString *stock_name = stock_map_name(map_name);
        NSString *description = [NSString stringWithFormat:@"File: %@.map|n",map_name];
        if(mod != nil) {
            description = [description stringByAppendingString:[NSString stringWithFormat:@"Version: %@|n",[mod objectForKey:@"human_version"]]];
            if(map_is_outdated(map_name, modDatabase)) {
                description = [description stringByAppendingString:@"Map is outdated!|nTo update, go to|nHaloMD and|nredownload it.|n"];
            }
        }
        else if([map_name isEqualToString:@"crossing"])
            description = [description stringByAppendingString:@"A Memorial|nto Heroes Fallen|n"];
        else if([map_name isEqualToString:@"barrier"])
            description = [description stringByAppendingString:@"So Close,|nYet So Far...|n"];
        else if([map_name isEqualToString:@"bloodgulch"])
            description = [description stringByAppendingString:@"The Quick|nand the Dead|n"];
        else if([stock_name isEqualToString:map_name]) {
            if(build_number_from_identifier(map_name) == 0)
                description = [description stringByAppendingString:@"Non-MD map|n"];
            else
                description = [description stringByAppendingString:@"Unlisted MD map|n"];
        }
        else
            description = [description stringByAppendingString:@"Full version map.|n"];
        
        size_t data_size = sizeof(*tag->references->string) * ([description length] + 1);
        tag->references[i].string = calloc(data_size,1);
        memcpy(tag->references[i].string, [description cStringUsingEncoding:NSUTF16LittleEndianStringEncoding], data_size);
        tag->references[i].length = data_size;
    }
    return tag;
}

/// This function will destroy an entire USTR tag generated by this plugin.
static void free_ustr_tag(UnicodeStringTag *tag) {
    if(tag == NULL) return;
    for(uint32_t i=0;i<tag->referencesCount;i++) {
        free(tag->references[i].string);
    }
    free(tag->references);
    free(tag);
}

/// This generates a map list that is used by Halo.
/// This value will have to be freed with free_map_list() at some point to prevent memory leaks.
/// Do NOT free the pointer to the original map list, as it's already being managed by Halo.
static MapListArray *generate_map_list_from_array(NSArray *array) {
    MapListArray *list = malloc(sizeof(MapListArray));
    list->count = [array count];
    list->list = malloc(list->count * sizeof(MapListEntry));
    
    for(uint32_t i=0;i<list->count;i++) {
        const char *name = [[[[array objectAtIndex:i]stringByDeletingPathExtension]lowercaseString]UTF8String];
        list->list[i].enabled = 1;
        list->list[i].index = i;
        list->list[i].name = calloc(strlen(name) + 1, sizeof(char));
        strcpy(list->list[i].name, name);
    }
    return list;
}

/// This destroys a map list generated by this plugin.
static void free_map_list(MapListArray *list) {
    if(list == NULL) return;
    for(uint32_t i=0;i<list->count;i++) {
        free(list->list[i].name);
    }
    free(list->list);
    free(list);
}

/// Taken from HaloMD. This function parses the map database and should be as independent on (Mac) OS X version as we'd like.
static NSDictionary *dictionary_from_path_without_extension(NSString *path_without_extension)
{
    NSDictionary *modsDictionary = nil;
    BOOL jsonSerializationExists = NSClassFromString(@"NSJSONSerialization") != nil;
    
    NSString *fileExtension = jsonSerializationExists ? @"json" : @"plist";
    NSString *fullPath = [path_without_extension stringByAppendingPathExtension:fileExtension];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
        if (!jsonSerializationExists)
        {
            modsDictionary = [NSDictionary dictionaryWithContentsOfFile:fullPath];
            if (modsDictionary == nil)
            {
                NSLog(@"Map List Failed decoding plist at %@", fullPath);
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
                    NSLog(@"Map List Failed decoding JSON: %@", error);
                }
            }
        }
    }
    
    return modsDictionary;
}

/// This function reloads the map list and destroys all created USTR tags. It is called every time a map is loaded.
static void reload_map_list(bool new_map) {
    static UnicodeStringTag *mp_tag_names = NULL;
    static UnicodeStringTag *mp_tag_descriptions = NULL;
    static HaloBitmap *mp_icons_bitmaps = NULL;
    
    if(mp_icons_bitmaps != NULL && mp_icons_bitmaps->pointer != 0xFFFFFFFF && !new_map) {
        halo_printf((void *)0,"The map list will be reloaded when the map is changed.");
        return;
    }
    
    if((void *)mp_icons_bitmaps < (void *)0x40440000 || (void *)mp_icons_bitmaps > (void *)0x41B00000)
        free(mp_icons_bitmaps);
    mp_icons_bitmaps = NULL;
    
    free_ustr_tag(mp_tag_names);
    mp_tag_names = NULL;
    
    free_ustr_tag(mp_tag_descriptions);
    mp_tag_descriptions = NULL;
    
    free_map_list(mp_map_list);
    mp_map_list = NULL;
    
    NSDictionary *modDatabase = dictionary_from_path_without_extension([application_support_path() stringByAppendingPathComponent:@"HaloMD_mods_list"]);
    
    NSArray *map_list = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:maps_directory() error:nil];
    
    [multiplayer_maps release];
    multiplayer_maps = [[NSMutableArray alloc]init];
    
    for(NSString *map in map_list) {
        // If it's not a .map file, we don't care.
        if([[map pathExtension] isEqualToString:@"map"] == NO) continue;
        
        // 2048-byte buffer, which will hold the entire header of the map file.
        char buffer[0x800];
        
        // Get the file data. Yep yep yep!
        FILE *file = fopen([[maps_directory() stringByAppendingPathComponent:map]UTF8String], "r");
        if(file == NULL) continue;
        
        // Make sure it's at least 2048 bytes. If not, it's not a valid map file.
        fseek(file,0,SEEK_END);
        size_t length = ftell(file);
        fseek(file,0,SEEK_SET);
        
        if(length < sizeof(buffer)) {
            fclose(file);
            continue;
        }
        
        fread(buffer, sizeof(buffer), 1, file);
        fclose(file);
        
        // This is the map file name and should be the same as the internal map name.
        NSString *identifier = [map stringByDeletingPathExtension];
        
        // Check "head" and "foot". If they're not equal, then we can ignore this sucker, as it's not a cache file.
        if(*(uint32_t *)(buffer) != 1751474532 || *(uint32_t *)(buffer + 0x7FC) != 1718579060) continue;
        
        // Check if the identifier and map name are identical. If not, then it's not valid.
        if(strcmp([identifier UTF8String],buffer + 0x20) != 0) continue;
        
        // Check if it's a Halo PC/MD map. We can ignore this if show_all_maps is set.
        if(*(uint8_t *)(0x62fdc) == 0x74 && *(uint32_t *)(buffer + 0x4) != *(uint8_t *)(0x62fdb) && !show_all_maps) continue;
        
        // Check if it's the latest installed. We can ignore this if show_outdated_maps is set.
        if(!is_latest_installed(identifier, map_list, modDatabase) && !show_outdated_maps) continue;
        
        // Now let's check if it's a multiplayer map.
        switch (*(uint16_t *)(buffer + 0x60)) {
            case SINGLE_PLAYER: {
                // TODO: Add handler for single player maps.
                break;
            }
            case MULTI_PLAYER: {
                [multiplayer_maps addObject:map];
            }
            default: {
                break;
            }
        }
    }
    
    size_t multiplayer_maps_count = [multiplayer_maps count];
    
    // Set MP maps count...
    *(uint32_t *)(0x3D2D84) = multiplayer_maps_count;
    mp_map_list = generate_map_list_from_array(multiplayer_maps);
    *(MapListEntry **)(0x3691c0) = mp_map_list->list;
    
    mp_tag_names = generate_map_names_from_array(multiplayer_maps, modDatabase);
    mp_tag_descriptions = generate_map_descriptions_from_array(multiplayer_maps, modDatabase);
    
    MapTag *tag_data = *(MapTag **)HALO_INDEX_LOCATION;
    for(uint32_t i=0;i<*(uint16_t *)(HALO_INDEX_LOCATION + TAG_COUNT_OFFSET);i++) {
        // Check if the class is a USTR tag. Map names and descriptions are guaranteed to be ustr tags regardless of how protected the map is.
        if(tag_data[i].classA == 1970500722) {
            if(strcmp(tag_data[i].nameOffset,TAG_MAP_NAMES) == 0) {
                tag_data[i].dataOffset = mp_tag_names;
            }
            if(strcmp(tag_data[i].nameOffset,TAG_MAP_DESCRIPTIONS) == 0) {
                tag_data[i].dataOffset = mp_tag_descriptions;
            }
        }
        
        // Check if the class is a BITM tag, and is the map icon. This cannot be protected, as well.
        if(tag_data[i].classA == 1651078253 && strcmp(tag_data[i].nameOffset,TAG_MAP_ICONS) == 0) {
            HaloBitmapTag *tag = (HaloBitmapTag *)(tag_data[i].dataOffset);
            for(uint32_t i=0;i<tag->sequenceCount;i++) {
                tag->sequence[i].finalIndex = multiplayer_maps_count;
            }
            if(mp_icons_bitmaps == NULL) {
                mp_icons_bitmaps = generate_map_bitmap_from_array(multiplayer_maps, tag_data[i].identity);
            }
            if(multiplayer_maps_count <= 21) {
                memcpy(tag->bitmap,mp_icons_bitmaps,[multiplayer_maps count] * sizeof(*tag->bitmap));
                free(mp_icons_bitmaps);
                mp_icons_bitmaps = tag->bitmap;
            }
            else {
                tag->bitmap = mp_icons_bitmaps;
                tag->bitmapsCount = multiplayer_maps_count;
            }
        }
    }
}

/// This function is called whenever a command is used in Halo's console.
static void intercept_command(const char *command,const char *errorResult, const char *commandName) {
    NSArray *args = [[NSString stringWithCString:command encoding:NSUTF8StringEncoding] componentsSeparatedByString:@" "];
    
    if ([[[args objectAtIndex:0] lowercaseString] isEqualToString:@"sv_maplist_show_outdated"]) {
        if([args count] == 2) show_outdated_maps = [[args objectAtIndex:1]boolValue];
        halo_printf(NULL,show_outdated_maps ? "true" : "false");
        reload_map_list(false);
        return;
    }
    else if ([[[args objectAtIndex:0] lowercaseString] isEqualToString:@"sv_maplist_show_all"]) {
        if([args count] == 2) show_all_maps = [[args objectAtIndex:1]boolValue];
        halo_printf(NULL,show_all_maps ? "true" : "false");
        reload_map_list(false);
        return;
    }
    else if ([[[args objectAtIndex:0] lowercaseString] isEqualToString:@"sv_map"]) {
        if([args count] > 1) {
            NSString *map_argument = [[args objectAtIndex:1]lowercaseString];
            if(build_number_from_identifier(map_argument) == 0) {
                uint32_t build = 0;
                for(NSUInteger i=0;i<[multiplayer_maps count];i++) {
                    NSString *possible_map = [[multiplayer_maps objectAtIndex:i]stringByDeletingPathExtension];
                    if([possible_map isEqualToString:map_argument]) {
                        build = 0;
                        break;
                    }
                    uint32_t possible_build = build_number_from_identifier(possible_map);
                    if(possible_build > build) {
                        if([[NSString stringWithFormat:@"%@_%u",map_argument,possible_build] isEqualToString:possible_map]) {
                            build = possible_build;
                        }
                    }
                }
                if(build > 0) {
                    NSMutableArray *args_mut = [args mutableCopy];
                    [args_mut replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%@_%u",map_argument,build]];
                    run_command([[args_mut componentsJoinedByString:@" "] UTF8String],errorResult,commandName);
                    [args_mut release];
                    return;
                }
            }
            else {
                NSArray *map_list = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:maps_directory() error:nil];
                if([map_list containsObject:[map_argument stringByAppendingPathExtension:@"map"]]) {
                    // 2048-byte buffer, which will hold the entire header of the map file.
                    char buffer[0x800];
                    
                    // Get the file data. Yep yep yep!
                    FILE *file = fopen([[maps_directory() stringByAppendingPathComponent:[map_argument stringByAppendingPathExtension:@"map"]]UTF8String], "r");
                    if(file == NULL) return;
                    
                    // Make sure it's at least 2048 bytes. If not, it's not a valid map file.
                    fseek(file,0,SEEK_END);
                    size_t length = ftell(file);
                    fseek(file,0,SEEK_SET);
                    
                    if(length < sizeof(buffer)) {
                        fclose(file);
                        return;
                    }
                    
                    fread(buffer, sizeof(buffer), 1, file);
                    fclose(file);
                    
                    // Check "head" and "foot". If they're not equal, then we can ignore this sucker, as it's not a cache file.
                    if(*(uint32_t *)(buffer) != 1751474532 || *(uint32_t *)(buffer + 0x7FC) != 1718579060) return;
                    
                    // Check if the identifier and map name are identical. If not, then it's not valid.
                    if(strcmp([map_argument UTF8String],buffer + 0x20) != 0) return;
                    
                    // Check if it's a Halo PC/MD map. We can ignore this if show_all_maps is set.
                    if(*(uint8_t *)(0x62fdc) == 0x74 && *(uint32_t *)(buffer + 0x4) != *(uint8_t *)(0x62fdb) && !show_all_maps) return;
                    
                    free_map_list(mp_map_list);
                    mp_map_list = generate_map_list_from_array([NSArray arrayWithObject:[map_argument stringByAppendingPathExtension:@"map"]]);
                    *(uint32_t *)(0x3D2D84) = 1;
                    *(MapListEntry **)(0x3691c0) = mp_map_list->list;
                }
            }
        }
    }
    run_command(command,errorResult,commandName);
}



- (id)initWithMode:(MDPluginMode)mode {
    self = [super init];
    if(self) {
        void *mapLimitInstructions = (void *)0x1558D6; //deleting the 18 map limit
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_WRITE);
        memset(mapLimitInstructions,0x90,5);
        mprotect((void *)0x155000,0x1000, PROT_READ|PROT_EXEC);
        
        mach_override_ptr((void *)0x11e3de, (const void *)intercept_command, (void **)&run_command);
    }
    return self;
}

- (void)mapDidBegin:(NSString *)mapName {
    reload_map_list(true);
}

- (void)mapDidEnd:(NSString *)mapName {}

@end
