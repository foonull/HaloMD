/*
 * Copyright (c) 2013, Null <foo.null@yahoo.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this
 * list of conditions and the following disclaimer in the documentation and/or
 * other materials provided with the distribution.
 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  MDNetworking.m
//  HaloMD
//
//  Created by null on 5/25/12.
//

#import "MDNetworking.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <arpa/inet.h>

#define MASTER_SERVER_ADDRESS "halo.macgamingmods.com"

@implementation MDNetworking

+ (void)cancelHostResolution:(NSValue *)hostRefValue
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	CFHostRef hostRef = [hostRefValue pointerValue];
	
	[NSThread sleepForTimeInterval:3];
	
	CFHostCancelInfoResolution(hostRef, kCFHostAddresses);
	
	CFRelease(hostRef);
	
	[autoreleasePool release];
}

+ (NSArray *)socketAddressesFromHost:(NSString *)host
{
	NSArray *socketAddresses = nil;
	
	CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)host);
	if (hostRef)
	{
		// Retain in case somehow miraculously our thread we will launch finishes before us
		CFRetain(hostRef);
		
		// this thread will take ownership of hostRef
		[NSThread detachNewThreadSelector:@selector(cancelHostResolution:) toTarget:self withObject:[NSValue valueWithPointer:hostRef]];
		
		CFStreamError streamError;
		if (CFHostStartInfoResolution(hostRef, kCFHostAddresses, &streamError))
		{
			Boolean didResolveAddresses;
			NSArray *temporaryAddresses = (NSArray *)CFHostGetAddressing(hostRef, &didResolveAddresses);
			if (didResolveAddresses)
			{
				socketAddresses = [[temporaryAddresses retain] autorelease];
			}
		}
		else
		{
			NSLog(@"Failed to lookup host %@ with error code %d, domain %ld", host, (int)streamError.error, streamError.domain);
		}
		
		CFRelease(hostRef);
	}
	
	return socketAddresses;
}

+ (NSString *)addressFromHost:(NSString *)host
{
	NSString *address = host;
	
	for (id resolvedAddressData in [self socketAddressesFromHost:host])
	{
		const struct sockaddr *socketAddress = [resolvedAddressData bytes];
		if (socketAddress)
		{
			char ipAddress[INET6_ADDRSTRLEN];
			if (socketAddress->sa_len == sizeof(struct sockaddr_in))
			{
				struct sockaddr_in *ipv4Address = (struct sockaddr_in *)socketAddress;
				if (inet_ntop(AF_INET, &(ipv4Address->sin_addr.s_addr), ipAddress, INET_ADDRSTRLEN) != NULL)
				{
					address = [NSString stringWithUTF8String:ipAddress];
					break;
				}
			}
			else if (socketAddress->sa_len == sizeof(struct sockaddr_in6))
			{
				struct sockaddr_in6 *ipv6Address = (struct sockaddr_in6 *)socketAddress;
				if (inet_ntop( AF_INET6, &(ipv6Address->sin6_addr), ipAddress, INET6_ADDRSTRLEN) != NULL)
				{
					address = [NSString stringWithUTF8String:ipAddress];
					break;
				}
			}
		}
	}
	
	return address;
}

+ (void)retrieveServersThread:(id)delegate
{
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	NSArray *retrievedServers = [self retrieveServers];
	
	[delegate performSelectorOnMainThread:@selector(retrievedServers:) withObject:retrievedServers waitUntilDone:NO];
	
	[autoreleasePool release];
}

+ (void)retrieveServers:(id)delegate
{
	[NSThread detachNewThreadSelector:@selector(retrieveServersThread:) toTarget:self withObject:delegate];
}

#define MAXDATASIZE 1024
+ (NSArray *)retrieveServers
{
	int sockfd;
	ssize_t numbytes;
	char buf[MAXDATASIZE];
	
	NSArray *resolvedAddresses = [[self class] socketAddressesFromHost:[NSString stringWithUTF8String:MASTER_SERVER_ADDRESS]];
	if (!resolvedAddresses)
	{
		return nil;
	}
	
	BOOL didConnect = NO;
	for (id resolvedAddressData in resolvedAddresses)
	{
		const struct sockaddr *socketAddress = [resolvedAddressData bytes];
		if (socketAddress != NULL)
		{
			// Set the port we want to connect to, socketAddressesFromHost: will not do this for us
			const uint16_t port = 29920;
			if (socketAddress->sa_len == sizeof(struct sockaddr_in))
			{
				((struct sockaddr_in *)socketAddress)->sin_port = htons(port);
			}
			else if (socketAddress->sa_len == sizeof(struct sockaddr_in6))
			{
				((struct sockaddr_in6 *)socketAddress)->sin6_port = htons(port);
			}
			
			if ((sockfd = socket(socketAddress->sa_family, SOCK_STREAM, IPPROTO_TCP)) == -1)
			{
				perror("client: socket");
				continue;
			}
			
			// Set the socket to non-blocking
			int flags = fcntl(sockfd, F_GETFL, 0);
			fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
			
			if (connect(sockfd, socketAddress, socketAddress->sa_len) == -1)
			{
				if (errno != EINPROGRESS)
				{
					close(sockfd);
					perror("client: connect");
					continue;
				}
				
				fd_set writefds;
				FD_ZERO(&writefds);
				FD_SET(sockfd, &writefds);
				
				struct timeval tv;
				tv.tv_sec = 4;
				tv.tv_usec = 0;
				
				if (select(sockfd + 1, NULL, &writefds, NULL, &tv) <= 0 || !FD_ISSET(sockfd, &writefds))
				{
					close(sockfd);
					NSLog(@"Socket was not set in select() while trying to connect");
					continue;
				}
			}
			
			// Restore blocking option
			fcntl(sockfd, F_SETFL, flags);
			
			didConnect = YES;
			break;
		}
	}
	
	if (!didConnect)
	{
		NSLog(@"Error: Could not find an address to connect to for master lobby server");
		return nil;
	}
	
	struct timeval tv;
	fd_set readfds;
	
	tv.tv_sec = 4;
	tv.tv_usec = 0;
	
	FD_ZERO(&readfds);
	FD_SET(sockfd, &readfds);
	
	if (select(sockfd+1, &readfds, NULL, NULL, &tv) <= 0)
	{
		NSLog(@"Error: Did not receive anything in select from lobby server in timely manner");
		close(sockfd);
		return nil;
	}
	
	NSMutableString *stringBuffer = [NSMutableString string];
	
	if (FD_ISSET(sockfd, &readfds))
	{
		while (YES)
		{
			if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1)
			{
				return nil;
			}
			else if (numbytes == 0)
			{
				break;
			}
			else
			{
				buf[numbytes] = '\0';
				[stringBuffer appendString:[NSString stringWithUTF8String:buf]];
			}
		}
	}
	else
	{
		NSLog(@"Error: Did not receive anything from lobby server in timely manner");
		close(sockfd);
		return nil;
	}
	
	close(sockfd);
	
	NSMutableArray *components = [[NSMutableArray alloc] initWithArray:[stringBuffer componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	
	NSMutableArray *newComponents = [[NSMutableArray alloc] init];
	
	for (NSString *component in components)
	{
		if ([component length] > 1)
		{
			if ([[component substringToIndex:1] isEqualToString:@"-"])
			{
				[newComponents addObject:[component substringFromIndex:1]];
			}
			else
			{
				[newComponents addObject:component];
			}
		}
	}
	
	[components release];
	
	if ([[[newComponents lastObject] componentsSeparatedByString:@":"] count] == 2)
	{
		[newComponents removeLastObject];
	}
	
	return [NSArray arrayWithArray:[newComponents autorelease]];
}

static BOOL socketInitialized = NO;
static int querySocket;
+ (void)createQuerySocket
{
	struct addrinfo hints;
	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_DGRAM;
	hints.ai_flags = AI_PASSIVE;
	
	struct addrinfo *serverInfo;
	if (getaddrinfo(NULL, "0", &hints, &serverInfo) != 0) //who cares about port
	{
		NSLog(@"Failed to call getaddrinfo");
		return;
	}
	
	struct addrinfo *serverInfoPointer = NULL;
	for (serverInfoPointer = serverInfo; serverInfoPointer != NULL; serverInfoPointer = serverInfoPointer->ai_next)
	{
		if ((querySocket = socket(serverInfoPointer->ai_family, serverInfoPointer->ai_socktype, serverInfoPointer->ai_protocol)) == -1)
		{
			perror("createQuerySocket: socket");
			continue;
		}
		
		break;
	}
	
	freeaddrinfo(serverInfo);
	
	if (serverInfoPointer == NULL)
	{
		NSLog(@"Failed to bind socket..");
	}
	else
	{
		socketInitialized = YES;
	}
}

+ (void)queryServerAtAddress:(NSString *)address port:(uint16_t)port
{
	if (!socketInitialized)
	{
		[self createQuerySocket];
	}
	
	if (socketInitialized)
	{
		const char *addressCString = [address UTF8String];
		char buffer[] = {0xFE, 0xFD, 0x00, 0x77, 0x6A, 0xBF, 0xBF, 0xFF, 0xFF, 0xFF, 0xFF};
		
		if ([[address componentsSeparatedByString:@"."] count] == 4) // inet_pton only takes dotted quad address when family is AF_INET
		{
			struct in_addr ipv4Address;
			if (inet_pton(AF_INET, addressCString, &ipv4Address) <= 0)
			{
				NSLog(@"Failed to parse ipv4 address: %@", address);
			}
			
			struct sockaddr_in socketAddress;
			memset(&socketAddress, 0, sizeof(struct sockaddr_in));
			socketAddress.sin_len = sizeof(struct sockaddr_in);
			socketAddress.sin_family = AF_INET;
			socketAddress.sin_port = htons(port);
			socketAddress.sin_addr = ipv4Address;
			
			if (sendto(querySocket, buffer, sizeof buffer, 0, (struct sockaddr *)&socketAddress, socketAddress.sin_len) <= 0)
			{
				NSLog(@"Failed to send data to %@", address);
			}
		}
		else
		{
			struct in6_addr ipv6Address;
			if (inet_pton(AF_INET6, addressCString, &ipv6Address) <= 0)
			{
				NSLog(@"Failed to parse ipv6 address: %@", address);
			}
			
			struct sockaddr_in6 socketAddress;
			memset(&socketAddress, 0, sizeof(struct sockaddr_in6));
			socketAddress.sin6_len = sizeof(struct sockaddr_in6);
			socketAddress.sin6_family = AF_INET6;
			socketAddress.sin6_port = htons(port);
			socketAddress.sin6_addr = ipv6Address;
			
			if (sendto(querySocket, buffer, sizeof buffer, 0, (struct sockaddr *)&socketAddress, socketAddress.sin6_len) <= 0)
			{
				NSLog(@"Failed to send data to %@", address);
			}
		}
	}
}

+ (NSArray *)receiveQueryAndGetIPAddress:(NSString **)retrievedIPAddress portNumber:(uint16_t *)retrievedPortNumber
{
	fd_set readfds;
	FD_ZERO(&readfds);
	FD_SET(querySocket, &readfds);
	
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	
	int selectResult = select(querySocket+1, &readfds, NULL, NULL, &tv);
	if (selectResult < 0)
	{
		return nil;
	}
	
	if (selectResult == 0)
	{
		return nil;
	}
	
	if (!FD_ISSET(querySocket, &readfds))
	{
		return nil;
	}
	
	const int bufferLength = 1024;
	char buffer[bufferLength];
	struct sockaddr socketAddress;
	socklen_t socketAddressLength = sizeof(struct sockaddr_in6);
	ssize_t sizeReceived = recvfrom(querySocket, buffer, sizeof buffer, 0, &socketAddress, &socketAddressLength);
	if (sizeReceived <= 0)
	{
		return nil;
	}
	
	char ipAddress[INET6_ADDRSTRLEN];
	if (socketAddress.sa_len == sizeof(struct sockaddr_in))
	{
		struct sockaddr_in *ipv4Address = (struct sockaddr_in *)&socketAddress;
		if (inet_ntop(AF_INET, &(ipv4Address->sin_addr.s_addr), ipAddress, INET_ADDRSTRLEN) == NULL)
		{
			return nil;
		}
	}
	else if (socketAddress.sa_len == sizeof(struct sockaddr_in6))
	{
		struct sockaddr_in6 *ipv6Address = (struct sockaddr_in6 *)&socketAddress;
		if (inet_ntop( AF_INET6, &(ipv6Address->sin6_addr), ipAddress, INET6_ADDRSTRLEN) == NULL)
		{
			return nil;
		}
	}
	else
	{
		return nil;
	}
	
	*retrievedIPAddress = [NSString stringWithUTF8String:ipAddress];
	
	uint32_t portValue = 0;
	
	if (socketAddress.sa_len == sizeof(struct sockaddr_in))
	{
		portValue = ntohs(((struct sockaddr_in *)&socketAddress)->sin_port);
	}
	else if (socketAddress.sa_len == sizeof(struct sockaddr_in6))
	{
		portValue = ntohs(((struct sockaddr_in6 *)&socketAddress)->sin6_port);
	}
	
	*retrievedPortNumber = portValue;
	
	NSMutableArray *fields = [NSMutableArray array];
	ssize_t sizeConsumed = 0;
	char *bufferPointer = buffer;
	char *beginStringPointer = bufferPointer;
	while (sizeConsumed < sizeReceived)
	{
		if (bufferPointer[sizeConsumed] == '\0')
		{
			NSData *fieldData = [NSData dataWithBytes:beginStringPointer length:bufferPointer + sizeConsumed - beginStringPointer + 1];
			[fields addObject:fieldData];
			
			beginStringPointer = bufferPointer + sizeConsumed + 1;
		}
		sizeConsumed++;
	}
	
	return fields;
}

@end
