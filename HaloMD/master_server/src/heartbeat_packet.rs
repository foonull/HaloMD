use std::str;

// Game state changes
pub const GAMEEXITED : u16 = 2;

// Broadcasted game name
const HALO_RETAIL : &'static str = "halor";

// Invalid local port of the server
const INVALID_LOCAL_PORT : u16 = 0;

// Halo game versions
const HALO_VERSION_1_09 : &'static str = "01.00.09.0620";
const HALO_VERSION_1_10 : &'static str = "01.00.10.0621";

// HaloMD uses 1.09, but Halo PC 1.10 is interoperable
const VALID_GAME_VERSIONS: [&'static str; 2] = [ HALO_VERSION_1_09, HALO_VERSION_1_10 ];

// This isn't the whole packet, just the stuff we care about.
pub struct HeartbeatPacket {
    pub localport: u16,     // Can't trust source port due to some routers using a different port than this.
    pub gamename: String,   // Must be HALO_RETAIL
    pub gamever: String,    // Must be HALO_VERSION_1_09 or HALO_VERSION_1_10 in case it's unjoinable.
    pub statechanged: u16   // If it's GAMEEXITED, then the server is shutting down.
}

impl HeartbeatPacket {
    pub fn from_buffer(buffer: &[u8]) -> Option<HeartbeatPacket> {
        let mut ret = HeartbeatPacket {localport: 0, gamename: String::new(), gamever: String::new(), statechanged: 0};

        let mut line_iterator = buffer.split(|b| *b == 0);
        loop {
            let key = match line_iterator.next() {
                None => break,
                Some(n) => str::from_utf8(n).unwrap_or("")
            };
            let value = match line_iterator.next() {
                None => break,
                Some(n) => str::from_utf8(n).unwrap_or("")
            };

            match key {
                "localport" => {
                    ret.localport = value.parse::<u16>().unwrap_or(0);
                },
                "statechanged" => {
                    ret.statechanged = value.parse::<u16>().unwrap_or(0);
                },
                "gamever" => {
                    ret.gamever = value.to_string()
                },
                "gamename" => {
                    ret.gamename = value.to_string()
                },
                _ => {}
            }
        }
        
        if ret.localport == INVALID_LOCAL_PORT || ret.gamename != HALO_RETAIL || !VALID_GAME_VERSIONS.contains(&&*ret.gamename) {
            None
        }
        else {
            Some(ret)
        }
    }
}
