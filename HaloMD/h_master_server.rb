#Copyright (c) 2013, Null <foo.null@yahoo.com>
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification,
#are permitted provided that the following conditions are met:
#
#Redistributions of source code must retain the above copyright notice, this
#list of conditions and the following disclaimer.
#
#Redistributions in binary form must reproduce the above copyright notice, this
#list of conditions and the following disclaimer in the documentation and/or
#other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
#ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#Copyright nil, 2012
#A Halo Master Server lobby alternative to gamespy, which will require its own client implementation
#Port 29910 on UDP and 29920 on TCP will both need to be open on the server running this

require 'socket'
require 'fileutils'

MY_ADDRESS = "halo.macgamingmods.com"
MY_PORT = 2305

OLD_MD_STATS_PATH = "md_old_stats.txt"
NEW_AND_OLD_MD_STATS_PATH = "md_new_and_old_stats.txt"

MASTER_SERVER_PORT = 29910
NAT_SERVER_PORT = 27900

GAME_VERSION = "01.00.09.0620"

class Game
	attr_reader :address, :port, :last_updated
	def initialize(address, port)
		@address = address
		@port = port
		@first_chance = true
		update()
	end
	
	def update
		@last_updated = Time.now
	end

	def first_chance?
		status = true
		if @first_chance
			@first_chance = false
		else
			status = false
		end
		status
	end
end

class MasterServer
	def initialize_file_counter(filepath)
		if not File.exist?(filepath)
			begin
				file = File.open(filepath, "w")
				file.write("0")
				file.close()
			rescue
				puts "Failed to write initial counter for #{filepath}"
			end
		end
	end

	def increment_file_counter(filepath)
		if File.exist?(filepath)
			begin
				file = File.open(filepath, "r")
				data = file.read
				file.close()

				counter = data.to_s.to_i + 1

				temp_path = filepath + "_"
				file = File.open(temp_path, "w")
				file.write(counter.to_s)
				file.close

				FileUtils.mv(temp_path, filepath)
			rescue
				puts "Failed to increment counter for #{filepath}"
			end
		end
	end

	def initialize
		@server = UDPSocket.new
		#it is important to use 0.0.0.0, not localhost or anything else
		@server.bind('0.0.0.0', MASTER_SERVER_PORT)
		
		@nat_server = UDPSocket.new
		@nat_server.bind('0.0.0.0', NAT_SERVER_PORT)

		@halo_server = UDPSocket.new
		@halo_server.bind('0.0.0.0', MY_PORT)

		@my_ip_address = IPSocket::getaddress(MY_ADDRESS)
		
		@tcp_server = TCPServer.open(29920)
		
		@games = []
		@query_message = [0xFE, 0xFD, 0x00, 0x77, 0x6A, 0xBF, 0xBF, 0xFF, 0xFF, 0xFF, 0xFF].pack('c*')
		
		@favorite_games = []
		
		dedi_file = 'dedis.txt'
		if File.exists?(dedi_file)
			File.open(dedi_file).each_line do |line|
				stripped_line = line.strip
				if not stripped_line.empty? and not stripped_line.match(/^#/)
					game_info = stripped_line.split(':')
					address = game_info[0]
					begin
						ipAddress = IPSocket::getaddress(address)
					rescue
						puts "Failed to lookup #{address}"
						ipAddress = address
					end
					port = 2302
					if game_info.length > 1
						port = game_info[1].to_i
					end
					
					@favorite_games << Game.new(ipAddress, port)
				end
			end
		else
			puts "Not using a dedicated server file"
		end

		initialize_file_counter(OLD_MD_STATS_PATH)
		initialize_file_counter(NEW_AND_OLD_MD_STATS_PATH)
		
		run()
	end
	
	def get_game(address, port)
		for game in @games
			if game.address == address and game.port == port
				return game
			end
		end
		nil
	end
	
	def run
		loop do
			results = select([@server, @tcp_server, @halo_server, @nat_server], nil, nil, 1)

			if results and results[0].include?(@halo_server)
				data, receiver = @halo_server.recvfrom(1024)
				if data.bytes.to_a.pack('c*') == @query_message
					message_data = open('packet_data').read
					@halo_server.send(message_data, 0, receiver[3], receiver[1])
					increment_file_counter(OLD_MD_STATS_PATH)
				end
			end
			
			if results and results[0].include?(@tcp_server)
				client = @tcp_server.accept

				lobby_addresses = @games.map {|game| "#{game.address}:#{game.port}"}

				begin
					#Attach client's IP address so he knows his external address
					fam, port, *addr = client.getpeername.unpack('nnC4')
					lobby_addresses << "#{addr.join('.')}:49149:3425"
				rescue
					puts "Failed to get client IP address"
					lobby_addresses << "127.0.0.1:49149:3425"
				end

				lobby_addresses << "#{@my_ip_address}:#{MY_PORT}"
				
				begin
					client.print(lobby_addresses.join("\n"))
				rescue
					puts "Failed to send data to client"
				end

				client.close()

				increment_file_counter(NEW_AND_OLD_MD_STATS_PATH)
			end

			if results and results[0].include?(@nat_server)
				data, receiver = @nat_server.recvfrom(1024)
				data_array = data.split("\0")

				if data_array.length >= 12 and data_array[2] == "localport" and data_array[11] == GAME_VERSION
					game_port = data_array[3].to_i
					if game_port > 0
						game = get_game(receiver[3], game_port)
						@games << Game.new(receiver[3], game_port) unless game
					end
				end
			end
			
			if results and results[0].include?(@server)
				data, receiver = @server.recvfrom(1024)

				#puts "From addr: #{receiver.join(',')}, msg: #{data}"
				#receiver[3] is the DNS/address, receiver[1] is the port number
				data_bytes = data.bytes.to_a
				#puts data_bytes
				if data_bytes.length > 40
					if (data_bytes[0] == 59 and data_bytes[2] == 24)
						#A player has joined a game (this could mean a game has started)
						#Request server query information
						game = get_game(receiver[3], receiver[1])
						if game
							game.update
						else
							@server.send(@query_message, 0, receiver[3], receiver[1])
						end
					elsif data_bytes[0] == 59 and data_bytes[1] == 5 and data_bytes[2] == 4
						#A player has left a game
						if data_bytes[-2] == 47 and data_bytes[-1] == 64 #check if the host has left
							@games.delete_if {|game| game.address == receiver[3] and game.port == receiver[1]}
						end
					elsif data_bytes[0] == 0 and data_bytes[1] == 119 and data_bytes[2] == 106 and data_bytes[3] == 191 and data_bytes[4] == 191
						#Game query information has been received
						game = get_game(receiver[3], receiver[1])
						if game
							game.update
						else
							data_array = data.split("\0")
							#do some kind of validation at least...
							if data_array.length >= 5 and data_array[4] == GAME_VERSION
								@games << Game.new(receiver[3], receiver[1])
							end
						end
					end
				end
			end
			
			current_time = Time.now
			
			@games.delete_if do |game|
				should_delete_game = false
				time_difference = current_time - game.last_updated
				if time_difference >= 65
					#Close the game due to inactivity
					should_delete_game = true
				elsif time_difference >= 45
					#Try to get a response from the game
					@server.send(@query_message, 0, game.address, game.port)
				end
				should_delete_game
			end

			for game in @favorite_games
				unless get_game(game.address, game.port)
					time_difference = current_time - game.last_updated
					if game.first_chance? or time_difference >= 60
						#Try to get a response from the game
						@server.send(@query_message, 0, game.address, game.port)
						game.update()
					end
				end
			end
		end
	end
end

#Create and run the Master Server
MasterServer.new

