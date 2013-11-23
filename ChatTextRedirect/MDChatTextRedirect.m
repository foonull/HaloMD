/*
 * Copyright (c) 2013, Null <foo.null@yahoo.com>
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

// Plug-in created mostly by 002

#import "MDChatTextRedirect.h"
#import "mach_override.h"

#define MDGameInSession 0

typedef enum
{
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
} ConsoleColor;

void (*consolePrintf)(int color, const char *format, ...) = (void *)0x1588a8;

void *(*oldChat)(int, const uint16_t *, int);
static void *textChatOverride(int unknownZero, const uint16_t *message, int unknownSize)
{
	if (*(uint8_t *)0x45DF30 != MDGameInSession)
	{
		@autoreleasepool
		{
			consolePrintf(NONE, "%s", [[NSString stringWithFormat:@"%S", message] cStringUsingEncoding:NSISOLatin1StringEncoding]);
		}
	}
	
	return oldChat(unknownZero, message, unknownSize);
}

@implementation MDChatTextRedirect

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		mach_override_ptr((void *)0x14D9A4, textChatOverride, (void **)&oldChat);
	}
	return self;
}

@end
