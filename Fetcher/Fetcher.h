/* Fetcher.h created by jolly on Fri 07-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#import "GeneralScanner.h"

@interface Fetcher : NSObject
{
    FileWriter		*fileWriter;
    GeneralScanner	*generalScanner;

    MTQueue		*stopRunningQueue;
    MTQueue		*sendQueue;
    MTQueue		*receiveQueue;

    TCPConnection    	*receivePort;
    TCPConnection      	*sendPort;
    
}



- (Fetcher *)initWithInPort:(TCPConnection *)inPort outPort:(TCPConnection *)outPort threads:(int)threads;

- (void)runSendingThread;
- (void)runReceivingThread;

- (void)runWorkingThread;


@end
