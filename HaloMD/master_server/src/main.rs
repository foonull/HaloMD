// Syntax: master_server [ip address (0.0.0.0 by default)]
// This was created for HaloMD.

// If the server does not respond in at least this many seconds, it will be dropped from the list.
const DROP_TIME : i64 = 60;

// Blacklist for blocking IPs. Separate with newlines.
// Blacklisting IPs ignores heartbeat and keepalive packets from an IP address.
// That means that servers that are banned will not be immediately removed, but will time out, instead.
const BLACKLIST_FILE : &'static str = "blacklist.txt";

// Read the blacklist every x amount of seconds.
const BLACKLIST_UPDATE_TIME : u32 = 60;

// Note: The master server must have TCP 29920 open and UDP 27900 open.


use std::net::{UdpSocket,TcpListener};
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
    let halo_socket = match UdpSocket::bind((&ip as &str,27900)) {
        Err(_) => {
            println!("Error creating a UDP socket at {}:27900.",ip);
            return;
        },
        Ok(halo_socket) => halo_socket
    };

    let client_socket = match TcpListener::bind((&ip as &str,29920)) {
        Err(_) => {
            println!("Error listening to TCP at {}:29920.",ip);
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
                match File::open(BLACKLIST_FILE) {
                    Ok(file) => {
                        let reader = BufReader::new(&file);
                        match reader.lines().collect() {
                            Err(_) => {
                                blacklist_ref.clear();
                            },
                            Ok(t) => {
                                *blacklist_ref = t;
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
                    Ok(ip) => ip.to_string().split(":").next().unwrap().to_string()
                };

                let mut ips = String::new();

                let servers_ref = servers_mut_tcp.lock().unwrap();
                let servers = (*servers_ref).iter();

                for j in servers {
                    ips = ips + &(j.to_string()) + "\n";
                }

                // Some number placed after the requester's IP. If you ask me, the source code was abducted by aliens, and this is a tracking number. Regardless, it's needed.
                ips = ips + &ip + ":49149:3425";
                let _ = client.write_all(ips.as_bytes());
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
            Ok((length, source)) => (length,source)
        };
        if length == 0 {
            continue;
        }
        let client_ip = source.to_string().split(":").next().unwrap().to_string();

        if buffer[0] == 3 || buffer[0] == 8 {
            let blacklist_ref = blacklist_udp.lock().unwrap();
            if blacklist_ref.contains(&client_ip) {
                continue;
            }

            // Heartbeat packet.
            if buffer[0] == 3 {

                let mut servers = servers_mut_udp.lock().unwrap();

                let packet = HeartbeatPacket::from_buffer(&buffer, length);

                if packet.localport != 0 && length > 5 && game_versions.contains(&packet.gamever) {
                    let updatetime = time::now().to_timespec().sec;
                    match servers.iter_mut().position(|x| x.ip == client_ip.clone() && x.port == packet.localport) {
                        None => {
                            let serverness = HaloServer { ip:client_ip.clone(), port: packet.localport, last_alive: updatetime };
                            (*servers).push(serverness);
                            continue;
                        }
                        Some(k) => {
                            servers[k].last_alive = updatetime;
                            if packet.statechanged == 2 {
                                servers.remove(k);
                            }
                        }
                    };
                }
            }

            // Keepalive packet. We need to rely on the origin's port for this, unfortunately.
            else if buffer[0] == 8 {
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
}
