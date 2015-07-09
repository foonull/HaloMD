// This isn't the whole packet, just the stuff we care about.
pub struct HeartbeatPacket {
    pub localport: u16,     // Actual port. Needed to get the real port in case NAT screws it up.
    pub gamename: String,   // Must be "halor"
    pub gamever: String,    // Must be 1.09 or 1.10 in case it's unjoinable.
    pub statechanged: u16   // If it's 2, then the server is shutting down.
}

// C strings are null terminated, so they end with a 0 byte.
fn get_string_from_c_string(buffer: &[u8], offset: usize, maxlen: usize) -> Option<String> {
    if offset < maxlen && buffer.len() >= (maxlen + offset) {
        let mut bytes : Vec<u8> = Vec::new();
        for i in (offset..buffer.len()) {
            if buffer[i] == 0 || i - offset == maxlen {
                break;
            }
            bytes.push(buffer[i]);
        }
        return Some(String::from_utf8(bytes).unwrap());
    }
    return None;
}

impl HeartbeatPacket {
    pub fn from_buffer(buffer: &[u8], length: usize) -> HeartbeatPacket {
        let mut ret = HeartbeatPacket {localport: 0, gamename: "".to_string(), gamever: "".to_string(), statechanged: 0};

        // Heartbeat packets are more than 5 bytes. The buffer should be bigger than the actual
        //      length we need.
        if length < 5 || length > buffer.len() || buffer[0] != 3 {
            return ret;
        }

        let mut offset = 5;
        let mut last_string = String::new();

        loop {
            // Loop until we can't get a string anymore.
            let value = match get_string_from_c_string(buffer,offset,length) {
                None => break,
                Some(val) => val
            };
            // Strings are separated as key1(0)value1(0)key2(0)value2(0)key3(0)value3(0)...
            if last_string == "" {
                last_string = value.clone();
            }
            else {
                // We need this because NAT will often hide the original port if the server is
                //      behind a router.
                if last_string == "localport" {
                    ret.localport = match value.parse::<u16>() {
                        Err(_) => 0,
                        Ok(val) => val
                    };
                }
                // Statechanged determines whether or not the server is shutting down or just
                //      updating information with the master server. If it's shutting down (2),
                //      then we need to remove it from the list immediately.
                else if last_string == "statechanged" {
                    ret.statechanged = match value.parse::<u16>() {
                        Err(_) => 0,
                        Ok(val) => val
                    };
                }
                // We need to make sure nobody is using an unjoinable version of Halo.
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
