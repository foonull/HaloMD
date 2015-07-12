use time::SteadyTime;

// Halo server is just an IP, port, and the time it last sent a packet.
pub struct HaloServer {
    pub ip: String,
    pub port: u16,
    pub last_alive: SteadyTime
}

// This converts it to ip:port.
impl ToString for HaloServer {
    fn to_string(&self) -> String {
        return self.ip.clone() + ":" + &(self.port.to_string());
    }
}

// Equality against a (ip: &str, port: u16) tuple
impl<'a> PartialEq<(&'a str, u16)> for HaloServer {
    fn eq(&self, other: &(&'a str, u16)) -> bool {
        let (ip, port) = *other;
        self.ip == ip && self.port == port
    }
}
