/* Fetcher.m created by jolly on Fri 07-Mar-1997 */

#import <HooverFramework/HooverFramework.h>

#import "Fetcher.h"
#import "Worker.h"

#import <unistd.h>			// for getpid


@implementation Fetcher


- (void)dealloc
{
    [fileWriter release];
    [generalScanner release];

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

    fileWriter		= [[FileWriter alloc] init];
    generalScanner	= [[GeneralScanner alloc] initWithConfiguration:[NSDictionary dictionaryWithContentsOfFile:@"HTTPClient.configuration"]];

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

    NSLog(@"Fetcher exits due to : %@",[stopRunningQueue pop]);
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
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        NSMutableDictionary *url = [receiveQueue pop];

        #if DEBUG
        NSLog(@"Have to retrieve:%@",[url description]);
        #endif
        
        [[Worker worker] retrieveUrl:url];
        [fileWriter writeUrlDatatoFile:[[url copy] autorelease]];
        
        if(![@"/robots.txt" isEqual:[url objectForKey:@"path"]])				// The contents of robots.txt will get sent to the HooverController
            [url removeObjectForKey:@"httpdata"];					// everything else will send the url without contents back
        
        {
            NSMutableArray	*newLinkArray;
            NSEnumerator	*oldLinkEnumerator;
            NSMutableDictionary *aLink;
            
            oldLinkEnumerator = [[url objectForKey:@"links"] objectEnumerator];
            newLinkArray = [NSMutableArray array];
            while( aLink = [oldLinkEnumerator nextObject])
            {
                if( [generalScanner urlIsWanted:aLink] )
                {
                    [newLinkArray addObject:aLink];
                }
                #if DEBUG
                else
                {
                    NSLog(@"General Scanner rejects: %@",[aLink description]);
                }
                #endif
            }
            [url setObject:newLinkArray forKey:@"links"];
        }
        [sendQueue push:url];
        [pool release];
    }
}


@end
