use std::str;

// This isn't the whole packet, just the stuff we care about.
pub struct HeartbeatPacket {
    pub localport: u16,     // Can't trust source port due to some routers using a different port than this.
    pub gamename: String,   // Must be "halor"
    pub gamever: String,    // Must be 1.09 or 1.10 in case it's unjoinable.
    pub statechanged: u16   // If it's 2, then the server is shutting down.
}

impl HeartbeatPacket {
    pub fn from_buffer(buffer: &[u8]) -> HeartbeatPacket {
        let mut ret = HeartbeatPacket {localport: 0, gamename: String::new(), gamever: String::new(), statechanged: 0};

        if buffer.len() < 5 || buffer[0] != 3 {
            return ret;
        }
        
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
        return ret;
    }
}
