/* Fetcher.m created by jolly on Fri 07-Mar-1997 */

#import <HooverFramework/HooverFramework.h>

#import "Fetcher.h"
#import "Worker.h"

#import <unistd.h>			// for getpid


@implementation Fetcher


- (void)dealloc
{
    [fileWriter release];
    
    [receivePort release];
    [sendPort release];

    [stopRunningQueue release];
    [sendQueue release];
    [receiveQueue release];
    
    [super dealloc];
}



- (Fetcher *)initWithInPort:(TCPConnection *)inPort outPort:(TCPConnection *)outPort threads:(int)threads;
{
    [super init];

    fileWriter		= [[FileWriter alloc] initWithFilenamePrefix:@"fetched/fetched.out" urlsPerFile:1000];

    receivePort		= [inPort retain];
    sendPort		= [outPort retain];

    stopRunningQueue	= [[MTQueue alloc] init];
    sendQueue		= [[MTQueue alloc] init];
    receiveQueue	= [[MTQueue alloc] init];

    [NSThread detachNewThreadSelector:@selector(runSendingThread)
                             toTarget:self
                           withObject:nil];
    [NSThread detachNewThreadSelector:@selector(runReceivingThread)
                             toTarget:self
                           withObject:nil];
    while( threads-- )
    {
        [NSThread detachNewThreadSelector:@selector(runWorkingThread)
                                 toTarget:self
                               withObject:nil];
    }

    NSLog(@"Fetcher initWithInPort:outPort:threads: exits due to : %@",[stopRunningQueue pop]);
    return self;
}


- (void)runSendingThread;
{
    while( ![stopRunningQueue count] )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        id			urlToSend;

        urlToSend = [sendQueue pop];
        if( (self != urlToSend) && [sendPort isValid] )
        {
            [sendPort writeData:[NSArchiver archivedDataWithRootObject:urlToSend]];
        }
        else
        {
            [stopRunningQueue push:@"send - no data"];
        }
        [pool release];
    }
    [stopRunningQueue push:@"sendThreadExit"];
}



- (void)runReceivingThread;
{
    while( ![stopRunningQueue count] )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        NSData			*dataRead;

        if( dataRead = [receivePort readData] )
        {
            [receiveQueue push:[NSUnarchiver unarchiveObjectWithData:dataRead]];
        }
        else
        {
            [stopRunningQueue push:@"receive - no data"];
        }
        [pool release];
    }
    [stopRunningQueue push:@"receiveThreadExit"];
}


- (void)runWorkingThread;
{
    while(1)
    {
        NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
        NSMutableDictionary 	*url = [receiveQueue pop];

        #if DEBUG
        NSLog(@"Fetcher runWorkingThread: Have to retrieve:%@",[url description]);
        #endif
        
        [[Worker worker] retrieveUrl:url];
        //if( [url objectForKey:@"pageid"] || [[url objectForKey:@"status"] isEqual:@"invalid"] )
        {
            [fileWriter writeUrlDatatoFile:[[url copy] autorelease]];
        }

        [url removeObjectForKey:@"httpdata"];					// everything else will send the url without contents back
        [url removeObjectForKey:@"textRepresentation"];				// everything else will send the url without contents back
        [url removeObjectForKey:@"links"];					// everything else will send the url without contents back
        [sendQueue push:url];

        [pool release];
    }
}


@end
