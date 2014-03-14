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
//  ZZModList.h
//  ModList
//
//  Created by Paul Whitcomb on 11/23/13.
//  Copyright (c) 2013 Zero2. All rights reserved.
//

#import "MDPlugin.h"

@interface ZZModList : NSObject <MDPlugin> {
    
}

struct unicodeStringTag {
    uint32_t referencesCount;
    struct unicodeStringReference *references;
    uint32_t zero;
} __attribute__((packed));

struct unicodeStringReference {
    uint32_t length;
    uint32_t zeroa;
    uint32_t unknown2;
    unichar *string;
    uint32_t zerob;
} __attribute__((packed));

struct bitmapBitmap {
    uint32_t bitmapSignature; //0x0
    uint16_t width; //0x4
    uint16_t height; //0x6
    uint16_t depth; //0x8
    uint16_t type; //0xA
    uint16_t format; //0xC
    uint16_t flags; //0xE
    uint16_t x; //0x10
    uint16_t y; //0x12
    uint32_t mipmap; //0x14
    uint32_t pixelOffset; //0x18
    uint32_t pixelCount; //0x1C
    uint32_t bitmapLoneID; //0x20
    uint32_t ffffffff; //0x24
    uint32_t zero; //0x28
    uint32_t unknown; //0x2C;
} __attribute__((packed));

struct bitmapSequence {
    char padding[0x20];
    uint16_t beginningIndex;
    uint16_t finalIndex;
    char padding1[0x1C];
} __attribute__((packed));

struct bitmapTag {
    char padding[0x54];
    uint32_t sequenceCount;
    struct bitmapSequence *sequence;
    uint32_t zero;
    uint32_t bitmapsCount;
    struct bitmapBitmap *bitmap;
} __attribute__((packed));

typedef enum {
    BARRIER = 8,
    BLOODGULCH = 9,
    CROSSING = 16,
} MapList;

typedef struct {
	uint32_t classA;
	uint32_t classB;
	uint32_t classC;
	uint32_t identity;
	char *nameOffset;
	void *dataOffset;
    uint32_t notInsideMap;
	char padding[0x4];
} __attribute__((packed)) MapTag;

typedef struct {
    char *name;
    uint32_t index;
    uint32_t enabled;
} MapListEntry;

@end
