/* Fetcher.h created by jolly on Fri 07-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>
#import <OmniNetworking/OmniNetworking.h>

#import "GeneralScanner.h"

@interface Fetcher : NSObject
{
    FileWriter		*fileWriter;
    GeneralScanner	*generalScanner;

    Queue		*stopRunningQueue;
    Queue		*sendQueue;
    Queue		*receiveQueue;

    TCPConnection    	*receivePort;
    TCPConnection      	*sendPort;
    
}



- (Fetcher *)initWithInPort:(TCPConnection *)inPort outPort:(TCPConnection *)outPort threads:(int)threads;

- (void)runSendingThread;
- (void)runReceivingThread;

- (void)runWorkingThread;


@end
