
#import "HFUDPSocket.h"


#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define DEF_SOCKET_BUFFER_SIZE 90000

@implementation HFUDPSocket

- init;
{
  [super init];
  mysocket = -1;
  return self;
}

- (void)dealloc;
{
  if( mysocket != -1) 
    close(mysocket);
}

+ socket;
{
  return [[[self alloc] init] autorelease];
}



- setLocalPortNumber:(u_short)portnumber allowingAddressReuse:(BOOL)addressreuse;
{
    int 	socketbuffersize = DEF_SOCKET_BUFFER_SIZE;
    struct 	sockaddr_in 	inet_socketaddress;
    struct 	protoent 	*ppe;

    bzero(&inet_socketaddress,sizeof(inet_socketaddress));
    inet_socketaddress.sin_family 	= AF_INET;
    inet_socketaddress.sin_addr.s_addr	= INADDR_ANY;
    inet_socketaddress.sin_port 	= htons(portnumber);

    
    if( NULL == (ppe=getprotobyname("udp")) )
    {
        NSLog(@"HFUDPSocket -setLocalPortNumber:allowingAddressReuse: getprotobyname() failed\n");
        return nil;
    }

    if( (mysocket = socket(PF_INET, SOCK_DGRAM, ppe->p_proto)) < 0)
    {
        NSLog(@"HFUDPSocket -setLocalPortNumber:allowingAddressReuse: socket() failed\n");
        return nil;
    }

    if( bind(mysocket,(struct sockaddr *)&inet_socketaddress, sizeof(inet_socketaddress)) < 0)
    {
        NSLog(@"HFUDPSocket -setLocalPortNumber:allowingAddressReuse: bind() failed\n");
        return nil;
    }
    
    if(setsockopt(mysocket, SOL_SOCKET, SO_RCVBUF, &socketbuffersize, sizeof(socketbuffersize)) < 0)
    {
        NSLog(@"HFUDPSocket -setLocalPortNumber:allowingAddressReuse: setsocketopt() failed\n");
        return nil;

    }
    return self;
}


- connectToHost:(NSHost *)aHost port:(u_short)portnumber;
{
    struct 	protoent 	*ppe;
	
	if( NULL == (ppe=getprotobyname("udp")) )
	{
		NSLog(@"HFUDPSocket -connectToHost: getprotobyname() failed\n");
		return nil;
	}
	if( (mysocket = socket(PF_INET, SOCK_DGRAM, ppe->p_proto)) < 0)
	{
		NSLog(@"HFUDPSocket -connectToHost: socket() failed\n");
		return nil;
    }
	if( 0 == inet_aton([[aHost address] cString],&(sendtoaddress.sin_addr.s_addr)) )
	{
		NSLog(@"HFUDPSocket -connectToHost: inet_aton() failed\n");
		return nil;
	}							
	sendtoaddress.sin_family	= AF_INET;
	sendtoaddress.sin_port 		= htons(portnumber);

	return self;
}



- (NSData *)readData;       
{
  char     databuffer[DEF_SOCKET_BUFFER_SIZE];
  u_int    datasize;
  
  if( 0>= (datasize = recv(mysocket, databuffer,DEF_SOCKET_BUFFER_SIZE, 0)) )
  {
       NSLog(@"HFUDPSocket -readData: recv() failed\n");
       return nil;
  }
  return [NSData dataWithBytes:databuffer length:datasize];
}



- (void)writeData:(NSData *)sendData;
{
		sendto(mysocket,[sendData bytes], [sendData length], 0,(struct sockaddr*)&(sendtoaddress),sizeof(sendtoaddress));
}
@end




