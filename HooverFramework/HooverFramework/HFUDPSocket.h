#import <Foundation/Foundation.h>
#include <netinet/in.h>
@interface HFUDPSocket:NSObject
{
  int mysocket;
  struct sockaddr_in sendtoaddress;
}

+ socket;
- setLocalPortNumber:(u_short)portnumber allowingAddressReuse:(BOOL)addressreuse;
- connectToHost:(NSHost *)aHost port:(u_short)portnumber;

- (NSData *)readData;
- (void)writeData:(NSData *)sendData;

@end
