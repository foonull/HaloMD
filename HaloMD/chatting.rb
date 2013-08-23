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

#Created by null, 2013

require 'xmpp4r'
require 'xmpp4r/muc'
require 'digest/md5'
require 'uri'

class Chatting
	def initialize
		@thread = nil
		@client = nil
		@muc = nil
		@thread_timer = 0.0
		@last_time = nil
		@host = "gekko.macgamingmods.com"
		@nick = nil
		@identifier = nil
		@time_format = '%I:%M:%S'
		@timeout_number = 0
	end
	
	def connect_and_auth(serial_key, nick)
		if not @thread
			if not @client
				self.process 'connection_initiating', Time.new.strftime(@time_format) + " Connecting to server...", nil, nil
				
				@nick = nick
				@identifier = Digest::MD5.hexdigest(Digest::MD5.hexdigest(serial_key))
				@timeout_number = (@timeout_number % 5) + 1
				@thread = Thread.new do
					begin
						@client = Jabber::Client.new(Jabber::JID::new("#{@identifier}#{@timeout_number}@#{@host}"))
						@client.connect
						@client.auth("superduper")
					rescue
						puts 'Failed to connect and auth'
						@client = nil
					end
				end
			else
				self.join_group_chat
			end
		end
	end
	
	def join_group_chat
		@muc = Jabber::MUC::SimpleMUCClient.new(@client)
		
		@muc.on_message { |time, nick, text|
			self.process nick == @nick ? 'my_message' : 'on_message', (time || Time.new).strftime(@time_format) + " <#{nick}> #{text}", nick, text
		}
		
		@muc.on_join {|time, nick|
			self.process 'on_join', (time || Time.new).strftime(@time_format) + " <#{nick}> joined", nick, nil
		}
		
		@muc.on_leave {|time, nick|
			self.process 'on_leave', (time || Time.new).strftime(@time_format) + " <#{nick}> left", nick, nil
		}
		
		@muc.on_self_leave{|time|
			self.process 'on_self_leave', (time || Time.new).strftime(@time_format) + " You exited the room...", nil, nil
		}
		
		@muc.on_subject {|time, nick, new_subject|
			if nick
				self.process 'on_subject', (time || Time.new).strftime(@time_format) + " <#{nick}> changed the topic to #{new_subject}", nick, new_subject
			else
				self.process 'on_subject', "Topic: #{new_subject}", nick, new_subject
			end
		}
		
		@muc.add_presence_callback {|presence|
			if presence
				self.presence_changed(presence)
			end
		}
		
		should_attempt_joining = true
		original_nick = String.new(@nick)
		nick_tag = 1
		
		while should_attempt_joining
			begin
				@muc.join(Jabber::JID.new("halomd@conference.#{@host}/#{@nick}"))
				should_attempt_joining = false
			rescue Jabber::ServerError => exception
				#handle nick conflict
				if exception.error.code == 409
					nick_tag += 1
					@nick = "#{original_nick}#{nick_tag}"
				else
					puts "Failed to join muc"
					puts exception.message
					should_attempt_joining = false
					@muc = nil
				end
			end
		end
		
		@muc
	end
	
	def exit
		if @muc and @muc.active? and @client and @client.is_connected?
			@muc.exit
			@muc = nil
		end
	end
	
	def roster
		result = nil
		if @muc and @muc.active?
			#@muc.roster is actually a hash, this sort of converts it to an array
			result = @muc.roster.map{|item| item}
		end
		result
	end
	
	def set_status(new_status)
		if @client and @client.is_connected? and @muc and @muc.active?
			new_presence = Jabber::Presence.new(nil, new_status)
			@muc.send(new_presence)
		end
	end
	
	def send_message(message)
		if @muc and not @muc.active?
			@muc = nil
		end
		if @muc and @client
			if message.length > 0
				if message[0, 1] == '/'
					command = message[1..-1]
					if ["users", "roster"].include? command
						self.process 'roster', "Users: " + self.roster.map {|roster_item| roster_item[0]}.join(", "), nil, nil
					elsif ["subject", "topic"].include? command
						self.process 'on_subject', "Topic: " + @muc.subject, nil, nil
					elsif ["clear"].include? command
						self.clear
					end
				else
					@muc.say message
				end
			end
		end
		@muc != nil and @client != nil
	end
	
	def poll
		if @thread
			if @thread.alive?
				if @last_time
					@thread_timer += (Time.now - @last_time)
				end
				@last_time = Time.now
				
				if @thread_timer >= 10.0
					Thread.kill(@thread)
					@thread = nil
					@client = nil
					self.process 'connection_failed_timeout', Time.new.strftime(@time_format) + " Failed to connect to the server (timed out)... Please try again in a few minutes.", nil, nil
				end
			else
				@thread = nil
				if not @client
					self.process 'connection_failed', Time.new.strftime(@time_format) + " Failed to connect to the server...", nil, nil
				elsif not self.join_group_chat
					self.process 'muc_join_failed', Time.new.strftime(@time_format) + " Failed to join the chat...", nil, nil
				else
					self.process 'muc_joined', Time.new.strftime(@time_format) + " You joined the chat...", @muc.nick, nil
				end
			end
		end
	end
end
