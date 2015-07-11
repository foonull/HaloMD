// Syntax: master_server [ip address (0.0.0.0 by default)]
// This was created for HaloMD.

// If the server does not respond in at least this many seconds, it will be dropped from the list.
const DROP_TIME : i64 = 60;

// Blacklist for blocking IPs. Separate with newlines. Any line that starts with a # is ignored.
// Blacklisting IPs ignores heartbeat and keepalive packets from an IP address.
// That means that servers that are banned will not be immediately removed, but will time out, instead.
const BLACKLIST_FILE : &'static str = "blacklist.txt";

// Read the blacklist every x amount of seconds.
const BLACKLIST_UPDATE_TIME : u32 = 60;

// Note: The master server must have TCP 29920 open and UDP 27900 open.
const BROADCAST_PORT_UDP : u16 = 27900;
const SERVER_LIST_PORT_TCP : u16 = 29920;

// Broadcast packet types.
const KEEPALIVE : u8 = 8;
const HEARTBEAT : u8 = 3;

// Game state changes
const GAMEEXITED : u16 = 2;

// Opcode info
const OPCODE_INDEX : usize = 0;
const OPCODE_AND_HANDSHAKE_LENGTH : usize = 5;

// Broadcasted game name
const HALO_RETAIL : &'static str = "halor";

use std::net::{UdpSocket,TcpListener,SocketAddr};
use std::net::SocketAddr::{V4,V6};
use std::io::{Write,BufReader,BufRead};
use std::env;
use std::fs::File;
use std::thread;
use std::sync::{Arc, Mutex};

extern crate time;

mod halo_server;
use halo_server::HaloServer;

mod heartbeat_packet;
use heartbeat_packet::HeartbeatPacket;

trait IPString {
    fn ip_string(&self) -> String;
}

impl IPString for SocketAddr {
    fn ip_string(&self) -> String {
        match *self {
            V4(ipv4) => ipv4.ip().to_string(),
            V6(ipv6) => "[".to_string() + &ipv6.ip().to_string() + "]"
        }
    }
}

fn main() {
    let count = env::args().count();
    let ip = if count == 2 {
        let j : Vec<_> = env::args().collect();
        j[1].to_string()
    }
    else if count == 1 {
        "0.0.0.0".to_string()
    }
    else {
        println!("Only one argument is allowed: the IP to bind to.");
        return;
    };

    // We need to bind on two different ports. If it failed to bind (invalid IP, port is taken), then we must make sure this is known.
    let halo_socket = match UdpSocket::bind((&ip as &str,BROADCAST_PORT_UDP)) {
        Err(error) => {
            println!("Error creating a UDP socket at {}:{}. {}.",ip,BROADCAST_PORT_UDP,error);
            return;
        },
        Ok(halo_socket) => halo_socket
    };

    let client_socket = match TcpListener::bind((&ip as &str,SERVER_LIST_PORT_TCP)) {
        Err(error) => {
            println!("Error listening to TCP at {}:{}. {}.",ip,SERVER_LIST_PORT_TCP,error);
            return;
        },
        Ok(client_socket) => client_socket
    };

    // Mutex for thread safety.
    let servers_halo: Vec<HaloServer> = Vec::new();
    let servers_mut_udp = Arc::new(Mutex::new(servers_halo));
    let servers_mut_tcp = servers_mut_udp.clone();
    let servers_mut_destruction = servers_mut_udp.clone();

    // Destruction thread. This will remove servers that have not broadcasted their presence in a while.
    thread::spawn(move || {
        loop {
            thread::sleep_ms(10 * 1000);
            let mut servers = servers_mut_destruction.lock().unwrap();
            let timenow = time::now().to_timespec().sec;
            servers.retain(|x| x.last_alive + DROP_TIME > timenow);
        }
    });

    // Blacklist mutex. Concurrency needs to be safe, my friend.
    let blacklist: Vec<String> = Vec::new();
    let blacklist_update = Arc::new(Mutex::new(blacklist));
    let blacklist_udp = blacklist_update.clone();

    // Blacklist read thread.
    thread::spawn(move || {
        loop {
            // Placed in a block so blacklist is unlocked before sleeping to prevent threads from being locked for too long.
            {
                let mut blacklist_ref = blacklist_update.lock().unwrap();
                blacklist_ref.clear();
                match File::open(BLACKLIST_FILE) {
                    Ok(file) => {
                        let reader = BufReader::new(&file);
                        match reader.lines().collect() {
                            Err(_) => {},
                            Ok(t) => {
                                let lines : Vec<String> = t;
                                for line in lines.iter().filter(|x| x.starts_with("#") == false) {
                                    println!("Added {} to blacklist.", line);
                                    blacklist_ref.push(line.clone());
                                }
                            }
                        }
                    },
                    Err(_) => {}
                };
            }
            thread::sleep_ms(BLACKLIST_UPDATE_TIME * 1000);
        }
    });

    // TCP server thread. This is for the HaloMD application.
    thread::spawn(move || {
        loop {
            for stream in client_socket.incoming() {
                let mut client = match stream {
                    Err(_) => continue,
                    Ok(the_stream) => the_stream
                };
                // Unwrap the IP.
                let ip = match client.peer_addr() {
                    Err(_) => continue,
                    Ok(ip) => ip.ip_string()
                };

                let mut ips = String::new();

                // Make servers_ref go out of scope to unlock it for other threads, since we don't need it.
                {
                    let servers_ref = servers_mut_tcp.lock().unwrap();
                    let servers = (*servers_ref).iter();

                    for j in servers {
                        ips.push_str(&(j.to_string()));
                        ips.push('\n');
                    }
                }

                // Some number placed after the requester's IP. If you ask me, the source code was abducted by aliens, and this is a tracking number. Regardless, it's needed.
                ips.push_str(&ip);
                ips.push_str(":49149:3425");

                // We may be here a while. Just in case...
                thread::spawn( move || {
                    let _ = client.write_all(ips.as_bytes());
                });
            }
        }
    });

    // UDP server is run on the main thread. Servers broadcast their presence here.

    // These are the allowed game versions. HaloMD and Halo PC 1.09 uses 01.00.09.0620, while Halo PC servers on 1.10 use 01.00.10.0621 (these are also joinable).
    let game_versions = [ "01.00.09.0620".to_string(), "01.00.10.0621".to_string() ];

    let mut buffer = [0; 2048];
    loop {
        let (length, source) = match halo_socket.recv_from(&mut buffer) {
            Err(_) => continue,
            Ok(x) => x
        };
        if length <= OPCODE_INDEX {
            continue;
        }

        if buffer[OPCODE_INDEX] != KEEPALIVE && buffer[OPCODE_INDEX] != HEARTBEAT {
            continue;
        }

        let client_ip = source.ip_string();

        let blacklist_ref = blacklist_udp.lock().unwrap();
        if blacklist_ref.contains(&client_ip) {
            continue;
        }

        // Heartbeat packet. These contain null-terminated C strings and are ordered in key1[0]value1[0]key2[0]value2[0]key3[0]value3[0] where [0] is a byte equal to 0x00.
        if buffer[OPCODE_INDEX] == HEARTBEAT && length > OPCODE_AND_HANDSHAKE_LENGTH {

            let mut servers = servers_mut_udp.lock().unwrap();

            match HeartbeatPacket::from_buffer(&buffer[OPCODE_AND_HANDSHAKE_LENGTH..length]) {
                None => {},
                Some(packet) => {
                    let updatetime = time::now().to_timespec().sec;
                    match servers.iter_mut().position(|x| x.ip == client_ip && x.port == packet.localport) {
                        None => {
                            if game_versions.contains(&packet.gamever) && &packet.gamename == HALO_RETAIL {
                                let serverness = HaloServer { ip:client_ip, port: packet.localport, last_alive: updatetime };
                                (*servers).push(serverness);
                            }
                        }
                        Some(k) => {
                            servers[k].last_alive = updatetime;
                            if packet.statechanged == GAMEEXITED {
                                servers.remove(k);
                            }
                        }
                    };
                }
            };
        }

        // Keepalive packet. We need to rely on the origin's port for this, unfortunately. This may mean that the source port is incorrect if the port was changed with NAT.
        else if buffer[OPCODE_INDEX] == KEEPALIVE {
            let mut servers_ref = servers_mut_udp.lock().unwrap();
            let servers = (*servers_ref).iter_mut();

            for i in servers {
                if i.ip == client_ip && i.port == source.port() {
                    i.last_alive = time::now().to_timespec().sec;
                    break;
                }
            }
        }
    }
}
