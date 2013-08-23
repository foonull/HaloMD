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

#Created by null, 2012

require 'socket'
require 'timeout'

class Networking
	def query_receive
		ret_value = nil
		begin
			if @query_socket
				results = select([@query_socket], nil, nil, 0.0)
				if results and results.length >= 1 and results[0].include?(@query_socket)
					data, receiver = @query_socket.recvfrom(1024)
					data_array = data.split("\0")
					ret_value = [data_array, receiver[3], receiver[1]]
				end
			end
		rescue
			ret_value = nil
			return ret_value
		end
		ret_value
	end
	
	def query_server(address, port)
		unless @query_socket
			@games = []
			begin
				@query_socket = UDPSocket.new
				@query_socket.bind('0.0.0.0', 0)
				@query_message = [0xFE, 0xFD, 0x00, 0x77, 0x6A, 0xBF, 0xBF, 0xFF, 0xFF, 0xFF, 0xFF].pack('c*')
			rescue
				@query_socket = nil
				return nil
			end
		end
		
		begin
			@query_socket.send(@query_message, 0, address, port)
		rescue
			return nil
		end
	end
end
