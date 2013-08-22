//
//  MDNetworking.m
//  HaloMD
//
//  Created by null on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
			if (getnameinfo(socketAddress, socketAddress->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST) == 0)
			{
				address = [NSString stringWithUTF8String:ipAddress];
				break;
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
		if (socketAddress)
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
				
				select(sockfd + 1, NULL, &writefds, NULL, &tv);
				
				if (!FD_ISSET(sockfd, &writefds))
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
	
	select(sockfd+1, &readfds, NULL, NULL, &tv);
	
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

@end
