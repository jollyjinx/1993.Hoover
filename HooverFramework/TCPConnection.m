#import <HooverFramework/TCPConnection.h>

#import <sys/types.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/socket.h>

@implementation TCPConnection
{
    BOOL			connectionisvalid;
    unsigned short int		localportnumber;
    int				mysocket;
}

- (void)dealloc;
{
#if DEBUG
    NSLog(@"TCPConnection: get's deallocated");
#endif
    if( -1 != mysocket )
        close(mysocket);
    
    [super dealloc];
}



- init
{
    [super init];

    mysocket = -1;
    connectionisvalid 	= NO;
    localportnumber	= 0;
    return self;
}

+ tcpConnection;
{
    return [[[self alloc] init] autorelease];
}

- (BOOL)connectToHost:(NSHost *)host andPort:(unsigned short int)port;
{
    struct in_addr	hostaddress;
    struct sockaddr_in	socketaddress;
    int			socketreuse=1;

    if( ! (hostaddress.s_addr = inet_addr([[host address] cString]) ) )
    {
        NSLog(@"TCPConnection:Can't get hostaddress.");
        return NO;
    }
    
    if( -1 == (mysocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) )
    {
        NSLog(@"TCPConnection:Can't create socket :%s", strerror(errno));
        return NO;
    }
    
    socketaddress.sin_family = AF_INET;
    socketaddress.sin_addr = hostaddress;
    socketaddress.sin_port = htons(port);


    if( -1 == setsockopt(mysocket, SOL_SOCKET, SO_KEEPALIVE, (char *)&socketreuse, sizeof(socketreuse)) )
    {
        NSLog(@"TCPConnection: can't set socketoption keepallive");
        return NO;
    }

    if( -1 == connect(mysocket,(struct sockaddr *)&socketaddress, sizeof(socketaddress)) )
    {
        NSLog(@"TCPConnection:Can't connect :%s", strerror(errno));
        return NO;
    }


    connectionisvalid=YES;
    return YES;
}


- (BOOL)startListeningOnLocalPort;
{
    return [self startListeningOnLocalPort:0];
}

-(BOOL)startListeningOnLocalPort:(unsigned short int)port;
{
    int			socketreuse 	= 1;
    struct sockaddr_in	socketaddress;
    int			socketaddresslength = sizeof(socketaddress);

    if( -1 == (mysocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) )
    {
        NSLog(@"TCPConnection:Can't create socket :%s", strerror(errno));
        return NO;
    }

    if( -1 == setsockopt(mysocket, SOL_SOCKET, SO_REUSEADDR , (char *)&socketreuse, sizeof(socketreuse)) )
    {
        NSLog(@"TCPConnection: can't set socketoption addressreuse");
        return NO;
    }
    socketreuse = 1;

    if( -1 == setsockopt(mysocket, SOL_SOCKET, SO_KEEPALIVE, (char *)&socketreuse, sizeof(socketreuse)) )
    {
        NSLog(@"TCPConnection: can't set socketoption keepallive");
        return NO;
    }

    socketaddress.sin_family      = AF_INET;
    socketaddress.sin_addr.s_addr = htonl(INADDR_ANY);
    socketaddress.sin_port        = htons(port);

    if( -1 == bind(mysocket, (struct sockaddr *)&socketaddress, sizeof(socketaddress)) )
    {
        NSLog(@"TCPConnection: can't bind socket.");
        return NO;
    }

    if( -1 == getsockname(mysocket, (struct sockaddr *)&socketaddress, &socketaddresslength) == -1)
    {
        NSLog(@"TCPConnection: can't find out portaddress.");
        return NO;
    }
    localportnumber = ntohs(socketaddress.sin_port);

    if( -1 == listen(mysocket,5) )
    {
        NSLog(@"TCPConnection: can't listen on socket.");
        return NO;
    }
    return YES;
}

-(void)acceptConnection;
{
    struct sockaddr_in 	acceptaddress;
    int			acceptaddresslength;
    int			newsocket;
    
    acceptaddresslength = sizeof(acceptaddress);

    if( -1 == (newsocket = accept(mysocket, (struct sockaddr *)&acceptaddress, &acceptaddresslength)) )
    {
        NSLog(@"TCPConnection: can't accept on socket.");
        connectionisvalid = NO;
        return;
    }
    close(mysocket);
    connectionisvalid = YES;
    mysocket = newsocket;
}

-(unsigned short int) localPortNumber;
{
    return localportnumber;
}

- (BOOL)isValid;
{
    return connectionisvalid;
}



- (int)writeData:(NSData *)data;
{
    int length = [data length];

    if( -1 == [self writeBytes:sizeof(length) fromBuffer:&length] )
        return -1;
    return [self writeBytes:[data length] fromBuffer:[data bytes]];
}


- (int)writeBytes:(int)length fromBuffer:(const void *)buffer;
{
    int byteswritten = 0;

    //signal(SIGPIPE, SIG_IGN);
    do
    {
        int written;
        if( 1 > ( written = send(mysocket , (void*)buffer+byteswritten , length-byteswritten, 0)) )
        {
            NSLog(@"TCPConnection: write error :%s  ( written %d )",strerror(errno),written);
            connectionisvalid = NO;
            //signal(SIGPIPE, SIG_DFL);
            return -1;
        }
        byteswritten+=written;
    }
    while( byteswritten < length );
    //signal(SIGPIPE, SIG_DFL);
    return byteswritten;
}


- (NSMutableData *)readData;
{
    NSMutableData	*dataObject;
    int 		length;
    
    if( -1 == [self readBytes:sizeof(length) intoBuffer:&length] )
        return nil;
    if( dataObject = [NSMutableData dataWithLength:length] )
        if( -1 == [self readBytes:length intoBuffer:[dataObject mutableBytes]])
            return nil;
    return dataObject;
}





- (int)readBytes:(int)length intoBuffer:(void *)buffer;
{
    int bytesread = 0;

    //signal(SIGPIPE, SIG_IGN);
    do
    {
        int readonce;
        if( 1 > (readonce =  recv(mysocket , buffer+bytesread , length-bytesread, 0 )) )
        {
            NSLog(@"TCPConnection: read error:%s  ( read %d )",strerror(errno),readonce);
            connectionisvalid = NO;
            //signal(SIGPIPE, SIG_DFL);
            return -1;
        }
        bytesread+=readonce;
    }
    while( bytesread < length );
    //signal(SIGPIPE, SIG_DFL);
    return bytesread;
}










@end

