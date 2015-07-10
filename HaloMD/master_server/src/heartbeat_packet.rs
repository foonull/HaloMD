// This isn't the whole packet, just the stuff we care about.
pub struct HeartbeatPacket {
    pub localport: u16,     // Can't trust source port due to some routers using a different port than this.
    pub gamename: String,   // Must be "halor"
    pub gamever: String,    // Must be 1.09 or 1.10 in case it's unjoinable.
    pub statechanged: u16   // If it's 2, then the server is shutting down.
}

// C strings are null terminated, so they end with a 0 byte.
fn get_string_from_c_string(buffer: &[u8]) -> String {
    let mut bytes : Vec<u8> = Vec::new();
    for i in buffer {
        if *i == 0 {
            break;
        }
        bytes.push(*i);
    }
    return match String::from_utf8(bytes) {
        Err(_) => String::new(),
        Ok(n) => n
    }
}

impl HeartbeatPacket {
    pub fn from_buffer(buffer: &[u8]) -> HeartbeatPacket {
        let mut ret = HeartbeatPacket {localport: 0, gamename: "".to_string(), gamever: "".to_string(), statechanged: 0};

        // Heartbeat packets are more than 5 bytes. The buffer should be bigger than the actual length we need.
        if buffer.len() < 5 || buffer[0] != 3 {
            return ret;
        }

        let mut offset = 5;
        let mut last_string = String::new();

        loop {
            if offset >= buffer.len() {
                break;
            }

            let value = get_string_from_c_string(&buffer[offset..buffer.len()]);

            // Strings are separated by 0 bytes.
            //      Example: key1(0)value1(0)key2(0)value2(0)key3(0)value3(0)...
            if last_string == "" {
                last_string = value.clone();
            }
            else {
                // We need this because NAT will often hide the original port if the server is behind a router.
                if last_string == "localport" {
                    ret.localport = match value.parse::<u16>() {
                        Err(_) => 0,
                        Ok(val) => val
                    };
                }
                // Statechanged determines whether or not the server is shutting down or just updating information with the master server. If it's shutting down (2), then we need to remove it from the list immediately.
                else if last_string == "statechanged" {
                    ret.statechanged = match value.parse::<u16>() {
                        Err(_) => 0,
                        Ok(val) => val
                    };
                }
                // We need to make sure servers are not using an unjoinable Halo version.
                else if last_string == "gamever" {
                    ret.gamever = value.clone();
                }
                // We need to make sure that people are using Halo PC or HaloMD.
                else if last_string == "gamename" {
                    ret.gamename = value.clone();
                }
                last_string = String::new();
            }
            offset = offset + value.len() + 1;
        }
        return ret;
    }
}
