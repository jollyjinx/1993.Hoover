/* DFetcher.m created by jolly on Tue 21-Oct-1997 */

#import "DFetcher.h"

@implementation DFetcher

static 	NSConditionLock	*keyLock;			// key stuff due to the fact that we get stored in a Dictionary as Key and are not copyable

+ (void) initialize
{
    keyLock = [[NSConditionLock alloc] init];
    [keyLock lock];
    [keyLock unlockWithCondition:0];
}

+ (NSNumber *)getNewKey;
{
    NSNumber 	*number;
    
    [keyLock lock];
    number = [NSNumber numberWithInt:[keyLock condition]];
    [keyLock unlockWithCondition:[keyLock condition]+1];
    return number;
}

- (NSNumber *)key;
{
    return key;
}


- (void)dealloc;
{
#if DEBUG
    NSLog(@"DFetcher gets deallocated");
#endif
    [fetcherController release];
    [stopRunningQueue release];
    [sendQueue release];
    [currentworkLoadLock release];
    [key release];
    [hostName release];
    
    [super dealloc];
}


- (DFetcher *)initWithFetcherController:(FetcherController *)fc;
{
    [super init];

    fetcherController 	= [fc retain];
    key			= [[DFetcher getNewKey] retain];
    stopRunningQueue   	= [[Queue alloc] init];
    currentworkLoadLock	= [[NSLock alloc] init];
    currentworkload	= 0;
    maximumworkload	= 0;
    sendQueue		= [[Queue alloc] init];
    hostName		= nil;

    return self;
}




+ (DFetcher *)dFetcherWithFetcherController:(FetcherController *)fc;
{
    return [[[self alloc] initWithFetcherController:fc] autorelease];
}



- (void)initiateConnection:(NSData *)data;
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    TCPConnection	*sendPort;
    TCPConnection	*receivePort;
    NSMutableDictionary	*connectionDictionary;

    if( ! (connectionDictionary = [NSUnarchiver unarchiveObjectWithData:data]))
    {
        NSLog(@"DFetcher can't unarchive connectionDictionary.");
        [pool release];
        [NSThread exit];
    }
    NSLog(@"Got invitation from: %@",[connectionDictionary description]);
    hostName = [[connectionDictionary objectForKey:@"hostname"] retain];

    receivePort = [TCPConnection tcpConnection];
    [receivePort connectToHost:[NSHost hostWithName:hostName]
                       andPort:[[connectionDictionary objectForKey:@"outport"] intValue]];
    sendPort = [TCPConnection tcpConnection];
    [sendPort connectToHost:[NSHost hostWithName:hostName]
                    andPort:[[connectionDictionary objectForKey:@"inport"] intValue]];
    maximumworkload = [[connectionDictionary objectForKey:@"maximumworkload"] intValue];

    [NSThread detachNewThreadSelector:@selector(runSendingThread:)
                             toTarget:self
                           withObject:sendPort];
    [NSThread detachNewThreadSelector:@selector(runReceivingThread:)
                             toTarget:self
                           withObject:receivePort];
 
    [fetcherController fetcherLogon:self];
    NSLog(@"DFetcher exits due to : %@",[stopRunningQueue pop]);
    [stopRunningQueue push:@"release me"];
    [sendQueue push:@"release me"];
    [fetcherController fetcherLogoff:self];
    [pool release];
}

- (NSString *)hostName;
{
    return hostName;
}

- (float)percentage;			// returns 0 to 1. 
{
    float percentage;
    [currentworkLoadLock lock];
    percentage = 1.0 - (float)( (float)currentworkload/(float)maximumworkload );
    [currentworkLoadLock unlock];
    return percentage;
}

- (NSComparisonResult) compare:(id)dFetcher;
{
    if( [self percentage] > [dFetcher percentage] )
        return NSOrderedDescending;							// 100%  >  10%
    return NSOrderedAscending;
}






- (void)fetchUrl:(NSMutableDictionary *)url;
{
    [sendQueue push:url];
    [currentworkLoadLock lock];
    currentworkload++;
    [currentworkLoadLock unlock];
}


- (void)runSendingThread:(TCPConnection *)sendPort;
{
    while( [sendPort isValid] && (![stopRunningQueue count]) )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        id			urlToSend;

        urlToSend = [sendQueue pop];
        if( urlToSend )
        {	
            [sendPort writeData:[NSArchiver archivedDataWithRootObject:urlToSend]];
        }
        else
        {
            [stopRunningQueue push:@"send myself"];
        }
        [pool release];
    }
    [stopRunningQueue push:@"sendThreadExit"];
}



- (void)runReceivingThread:(TCPConnection *)receivePort;
{
    while( [receivePort isValid] && (![stopRunningQueue count]) )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        NSData			*data;

        if( data = [receivePort readData])
        {
            NSMutableDictionary	*retrievedDictionary;
            
            retrievedDictionary = [NSUnarchiver unarchiveObjectWithData:data];
            [fetcherController retrievedUrl:retrievedDictionary dFetcher:self];
            [currentworkLoadLock lock];
            currentworkload--;
            [currentworkLoadLock unlock];
        }
        else
        {
            [stopRunningQueue push:@"receive - no data"];
        }
        [pool release];
    }
    [stopRunningQueue push:@"receiveThreadExit"];
}






@end
