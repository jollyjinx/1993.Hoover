
#import <Foundation/Foundation.h>

@interface TCPConnection : NSObject
{
    BOOL			connectionisvalid;
    unsigned short int		localportnumber;
    int				mysocket;
}

+ tcpConnection;

- (BOOL)connectToHost:(NSHost *)host andPort:(unsigned short int)port;

- (BOOL)startListeningOnLocalPort;
- (BOOL)startListeningOnLocalPort:(unsigned short int)port;
- (unsigned short int) localPortNumber;
-(void)acceptConnection;


- (BOOL)isValid;

- (int)writeData:(NSData *)data;
- (int)writeBytes:(int)length fromBuffer:(const void *)buffer;

- (NSMutableData *)readData;
- (int)readBytes:(int)length intoBuffer:(void *)buffer;


@end

