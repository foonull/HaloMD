HaloMD
======

HaloMD extends the life of Halo and makes mods fun again for the Mac.

HaloMD is a fairly ambitious project. Its source code notably shows off:

- Querying info from Halo game servers
- Writing a keygen (although not necessary) by analyzing Halo's code
- Running through Halo maps querying/altering for info.
- Altering Halo userdata such as game profiles
- Injecting code to alter the game at run-time
- Adding a XMPP chat-room client
- Implementing 3rd party support for adding and updating mods, with delta binary patches
- Writing a master server replacement by sniffing packets

Source code unless mentioned otherwise (eg: *keygen*, *mach_override*, *crc32forge.py*, *DSClickableURLTextField*, *SCEvents*) is under BSD 2-clause license.

Artwork and audio files are not under this license.

Due to file size restrictions, this repository does not bundle all the data to run HaloMD from source properly. Copy your Maps folder that is inside of your HaloMD.app (in *Contents/Resources/Data/DoNotTouchOrModify*) and paste it into *HaloMD/Data/DoNotTouchOrModify/*

Visit the [HaloMD website](http://www.halomd.net) for more info.