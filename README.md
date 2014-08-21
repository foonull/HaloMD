HaloMD
======

HaloMD extends the life of Halo and makes mods fun again for the Mac.

HaloMD is a fairly ambitious project. It notably shows off:

- Querying info from Halo game servers
- Writing a keygen (although not necessary) by analyzing Halo's code
- Altering Halo map file and blam data
- Adding support for adding/updating mods, with delta binary patches
- Adding support for adding extensions/plug-ins; a way to change the game at run-time
- Writing a master server replacement by sniffing packets
- Integrating a XMPP chat-room client

Most source code files unless noted otherwise are under BSD 2-clause license. Check the source code file in question to verify its license.

Artwork and audio files are not under a license.

Due to file size restrictions, this repository does not bundle all the data to run HaloMD from source properly. Copy your Maps folder that is inside of your HaloMD.app (in *Contents/Resources/Data/DoNotTouchOrModify*) and paste it into *HaloMD/Data/DoNotTouchOrModify/*

HaloMD may require a recent version of Xcode to build, but should run on intel Macs back to OS X 10.6

Visit the [HaloMD website](http://www.halomd.net) for more info.
