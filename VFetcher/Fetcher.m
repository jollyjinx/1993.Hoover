/* Fetcher.m created by jolly on Fri 07-Mar-1997 */

#import "Fetcher.h"
#import "Worker.h"

@protocol WorkerProtocol
- (oneway void)retrieveUrl:(NSMutableDictionary *)url;
@end


@implementation Fetcher
{
    FetcherController	*hooverObject;
    ThreadController 	*threadController;
    NSMutableArray	*availableWorkers;

    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
    int   	   	availableconnections;
}

- (void)dealloc
{
    [threadController release];
    [hooverObject release];
    [availableWorkers release];
    
    [userAgentName release];
    [userAgentMail release];
    [httpProxyDictionary release];
    
    [super dealloc];
}

- (Fetcher *)initWithMaximumConnections:(int)maxcon hooverObject:(FetcherController *)dObject;
{
    [super init];

    
    httpProxyDictionary = nil;
    availableconnections = maxcon;
    
    availableWorkers = [[NSMutableArray alloc] init];
    threadController = [[ThreadController alloc] initWithRootObject:self];
    hooverObject = [dObject retain];
    return self;
}

- (void)workerWantsWork:(Worker *)proxyWorker;
{
    [availableWorkers addObject:proxyWorker];
}

- (void)detachWorkingThreads;
{
    int i = availableconnections;
    Worker *workerObject;
    
    while( i-- )
    {
        workerObject = [[Worker alloc] init];
        [NSThread detachNewThreadSelector:@selector(runWithController:)
                                 toTarget:workerObject
                               withObject:threadController];
    }
    while([availableWorkers count] < availableconnections )
    {
        [[NSRunLoop currentRunLoop] runMode:NSConnectionReplyMode
                                 beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode: NSConnectionReplyMode]];
    }
}

- (oneway void)fetchUrl:(bycopy NSMutableDictionary *)url;
{
    if(![availableWorkers count])
    {
        NSLog(@"Fetcher got work even though all workers are busy.");
        exit(1);
    }
    [[availableWorkers objectAtIndex:0] retrieveUrl:url];
    [availableWorkers removeObjectAtIndex:0];
}

- (void) retrievedUrl:(NSMutableDictionary *)url withWorker:(Worker *)proxyWorker;
{
    [availableWorkers addObject:proxyWorker];
    [hooverObject retrievedUrl:url];
}


- (void) setUserAgentName:(bycopy NSString *)uaName;
{
    userAgentName = [uaName retain];
}
- (bycopy NSString*)userAgentName;
{
    return userAgentName;
}


- (void) setUserAgentMail:(bycopy NSString *)uaMail;
{
    userAgentMail = [uaMail retain];
}
- (bycopy NSString*)userAgentMail;
{
    return userAgentMail;
}


- (void) setHttpProxy:(bycopy NSMutableDictionary *)uaProxy;
{
    httpProxyDictionary = [uaProxy retain];
}
- (bycopy NSMutableDictionary *)httpProxyDictionary;
{
    return httpProxyDictionary;
}


- (bycopy NSString *)hostname;
{
    return [NSString stringWithFormat:@"%@:%d",[[NSHost currentHost] name],getpid()];
}
- (int)availableConnections;
{
    return availableconnections;
}

- (void) ping;
{
    #if DEBUG
        NSLog(@"pong");
    #endif
    return;
}
@end
