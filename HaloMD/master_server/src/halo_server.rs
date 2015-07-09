// Halo server is just an IP, port, and the time it last sent a packet.
pub struct HaloServer {
    pub ip: String,
    pub port: u16,
    pub last_alive: i64
}

// This converts it to ip:port.
impl ToString for HaloServer {
    fn to_string(&self) -> String {
        return self.ip.clone() + ":" + &(self.port.to_string());
    }
}

// Does what it says, pretty much.
impl Clone for HaloServer {
    fn clone(&self) -> Self {
        return HaloServer {ip: self.ip.to_string(), port: self.port, last_alive: self.last_alive};
    }
}
