HaloMD
======

HaloMD extends the life of Halo and makes mods fun again for the Mac.

HaloMD is a fairly ambitious project. It notably shows off:

- Querying info from Halo game servers
- Implementing support for adding versioned mods via a database, and updating them with delta binary patches
- Extending the game with extensions, which is a way of changing the game at run-time
- Writing a master server replacement from our packet sniffing research
- Integrating a XMPP chat-room client for folk to get together & play

Most source code files unless noted otherwise are under BSD 2-clause license. Check the source code file in question to verify its license.

Artwork and audio files are not under a license.

Due to file size restrictions, this repository does not bundle all the data to run HaloMD from source properly. Copy your Maps folder that is inside of your HaloMD.app (in *Contents/Resources/Data/DoNotTouchOrModify*) and paste it into *HaloMD/Data/DoNotTouchOrModify/*

HaloMD may require a recent version of Xcode to build, and OS X 10.7 or later to run.

Visit the [HaloMD website](http://www.halomd.net) for more info.
