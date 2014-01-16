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

//
//  MDPlugin.h
//  HaloMD
//
//  Created by null on 12/15/13.
//

#import <Foundation/Foundation.h>

// A MD plug-in is expected to implement this protocol

@protocol MDPlugin <NSObject>

// You should have NSPrincipalClass set to your class name that implements this protocol
// You should have CFBundleVersion in your info.plist set, and it should be an integer greater than 0 that increases for each version you send out
// It would also be a good idea to set CFBundleShortVersionString, your humanized friendly version (eg: 1.0)

// If you set MDGlobalPlugin key to true in your info.plist, then your plug-in will show up in the menu and the user will be able to enable or disable it
// If you set MDMapPlugin key to true in your info.plist, then your plug-in can be a dependence to map mods in the database
// It is possible for a plug-in to have both of these keys set to true, and distinguish at run-time which mode it is being run through. At least one of these keys must be set to true.
// In particular, if a plug-in has both keys set to true, then it will run through global mode if the plug-in is enabled by the user, otherwise it could run through map mode if it's disabled by the user and if a map requires the plug-in.
// If you are not using one of the modes, you should still have the key in your plist and set its value to false

// If you want to test a map-based plug-in without first submitting the map to the database, duplicate HaloMD_mods_list.json and rename the copy to HaloMD_mods_list_dev.json (in HaloMD's app support folder), add a new entry for your map and change its identifier and create a "plug-ins" key which is an array of plug-in name strings. If you're on OS X 10.6 or below, do the same except with a plist instead of a json.

typedef enum
{
	// A plug-in at runtime runs through one of these modes (but not both)
	MDPluginGlobalMode, // Plug-in is not owned by a map and is enabled by the user's will. Can only be run if MDGlobalPlugin key in info.plist is set to true
	MDPluginMapMode // Plug-in is owned by a map and is not being enabled by the user's will. Can only be run if MDMapPlugin key in info.plist is set to true
} MDPluginMode;

// For all the methods below an auto release pool is set up.
// If you use Obj-C code elsewhere like in a function hook, you will be responsible for setting one up yourself.

// If you have a map based plug-in that is not meant to be run in global mode, you are either encouraged to: a) code-sign your plug-in preventing the info.plist from being modified, or b) return nil
- (id)initWithMode:(MDPluginMode)mode;

// For the methods below via MDPluginMapMode, they will only be called if mapName requires the plug-in.
// For MDPluginGlobalMode, they will be called for any map that is being switched to, including ui and b30 (the strings won't be exactly ui and b30, log them to see what they are)

// These two methods are the ideal place to enable and disable modifications, especially vital for plug-ins running via MDPluginMapMode
- (void)mapDidBegin:(NSString *)mapName;
- (void)mapDidEnd:(NSString *)mapName;

@end
