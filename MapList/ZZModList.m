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

@implementation ZZModList

typedef enum {
    MAGICISWAITING = 3,
    BARRIER = 8,
    BLOODGULCH = 9,
    CROSSING = 16,
    MODDED = 18
} MapList;

static void (*oldOverrideList)(char *a) = NULL;
static void overrideList(char *a)
{
    oldOverrideList(a); //init stuff
    *(uint32_t *)0x3D2D84 = 0x5; //number of maps
    *(uint32_t *)(*((int32_t *)0x3691c0) + (0 + 0 * 0x2) * 0x4) = *(uint32_t *)(*((int32_t *)0x3691c0) + (BLOODGULCH + BLOODGULCH * 0x2) * 0x4);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (0 + 0 * 0x2) * 0x4 + 0x8) = *(uint32_t *)(*((int32_t *)0x3691c0) + (BLOODGULCH + BLOODGULCH * 0x2) * 0x4 + 0x8);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (0 + 0 * 0x2) * 0x4 + 0x4) = BLOODGULCH;
    
    *(uint32_t *)(*((int32_t *)0x3691c0) + (1 + 1 * 0x2) * 0x4) = *(uint32_t *)(*((int32_t *)0x3691c0) + (CROSSING + CROSSING * 0x2) * 0x4);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (1 + 1 * 0x2) * 0x4 + 0x8) = *(uint32_t *)(*((int32_t *)0x3691c0) + (CROSSING + CROSSING * 0x2) * 0x4 + 0x8);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (1 + 1 * 0x2) * 0x4 + 0x4) = CROSSING;
    
    *(uint32_t *)(*((int32_t *)0x3691c0) + (2 + 2 * 0x2) * 0x4) = *(uint32_t *)(*((int32_t *)0x3691c0) + (BARRIER + BARRIER * 0x2) * 0x4);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (2 + 2 * 0x2) * 0x4 + 0x8) = *(uint32_t *)(*((int32_t *)0x3691c0) + (BARRIER + BARRIER * 0x2) * 0x4 + 0x8);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (2 + 2 * 0x2) * 0x4 + 0x4) = BARRIER;
    
    *(uint32_t *)(*((int32_t *)0x3691c0) + (4 + 4 * 0x2) * 0x4) = *(uint32_t *)(*((int32_t *)0x3691c0) + (MODDED + MODDED * 0x2) * 0x4);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (4 + 4 * 0x2) * 0x4 + 0x8) = *(uint32_t *)(*((int32_t *)0x3691c0) + (MODDED + MODDED * 0x2) * 0x4 + 0x8);
    *(uint32_t *)(*((int32_t *)0x3691c0) + (4 + 4 * 0x2) * 0x4 + 0x4) = MODDED;
    return;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
        mach_override_ptr((void *)0x15596c, overrideList, (void **)&oldOverrideList);
    }
    return self;
}

@end
