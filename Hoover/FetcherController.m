/* FetcherController.m created by jolly on Thu 06-Mar-1997 */

#import "FetcherController.h"

#define MAXIMUM_QUEUESIZE 50
#define INITIAL_PONGCOUNT 10
#define REMOTE_REQUEST_TIME 2.0
#define REMOTE_REPLY_TIME 2.0

#define	CONDITION_QUEUE_EMPTY		0
#define	CONDITION_QUEUE_NOT_EMPTY	1

#define CONNECTION_NAME @"Hoover"
#define MAXIMUM_CONNECTIONS 20


#if DEBUG

#define	CONNECTIONLOG(STRING)						\
NSLog(@"%@\n\t\t(%d Fetchers)\n\t\t(%d intermediate connections )(%d used connections )\n\t\t(%d urls in work) (%d urls in queue)",STRING,    	\
          [remoteFetchersSortedArray count],										\
          [intermediateConnectionDictionary count],[usedConnectionDictionary count],					\
          [fetcherWorkDictionary count],[workQueue count]);								\
          showvalidconnections();											\
    assert([remoteFetchersSortedArray count]==[usedConnectionDictionary count]);					
#endif




@protocol FetcherProtocol
- (oneway void)fetchUrl:(bycopy NSMutableDictionary *)url;
- (void)ping;
@end

static NSComparisonResult comparedistant(NSMutableDictionary *server1, NSMutableDictionary *server2, int context)
{
    NSNumber *number1,*number2;
    
    if( ! (number1=[server1 objectForKey:@"availableConnections"]) ) return NSOrderedAscending;
    if( ! (number2=[server2 objectForKey:@"availableConnections"]) ) return NSOrderedDescending;
    return [number1 compare:number2];
}

static void showvalidconnections()
{
    int count=0;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if( [[NSConnection allConnections] count] )
    {
        NSEnumerator 	*enumerator;
        NSConnection 	*connection;

        enumerator = [[NSConnection allConnections] objectEnumerator];
        while( connection = [enumerator nextObject])
        {
            if([connection isValid]) count++;
        }
    }
    NSLog(@"All Connections : %d valid:%d",[[NSConnection allConnections] count],count);
    [pool release];
}

@implementation FetcherController
{
    NSString		*connectionName;
    NSConnection	*waitingConnection;
    NSMutableDictionary	*intermediateConnectionDictionary;
    NSMutableDictionary	*usedConnectionDictionary;

    SortedArray		*remoteFetchersSortedArray;
    NSMutableArray	*workQueue;
    NSConditionLock	*workQueueLock;
    NSMutableDictionary	*fetcherWorkDictionary;

    HooverController	*hooverController;
}


- (void)dealloc;
{
    [connectionName release];
    [waitingConnection release];
    [intermediateConnectionDictionary release];
    [usedConnectionDictionary release];
    
    [remoteFetchersSortedArray release];
    [fetcherWorkDictionary release];
    [workQueue release];
    [workQueueLock release];

    [hooverController release];
    
    [super dealloc];
}


- (FetcherController *)init;
{
    [super init];
    connectionName = CONNECTION_NAME;
    workQueue = [[NSMutableArray alloc] init];
    workQueueLock = [[NSConditionLock alloc] init];
    
    waitingConnection = nil;
    intermediateConnectionDictionary = [[NSMutableDictionary alloc] init];
    usedConnectionDictionary = [[NSMutableDictionary alloc] init];

    
    remoteFetchersSortedArray = [[SortedArray alloc] init];
    [remoteFetchersSortedArray sortUsingFunction:(int (*)(id, id, void *))&comparedistant context:NULL];
    fetcherWorkDictionary = [[NSMutableDictionary dictionary] retain];
    return self;
}


- (void)runWithHooverController:(HooverController *)hc;
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop		*runLoop = [NSRunLoop currentRunLoop];
    NSAutoreleasePool	*runLoopAutoreleasePool;
    NSDate		*nextPingDate;

    hooverController = [hc retain];
    nextPingDate = [[NSDate date] retain];

    while(1)
    {	
        NS_DURING
        //NSLog(@"Fetcher loop");
        runLoopAutoreleasePool = [[NSAutoreleasePool alloc] init];

        NS_DURING
        if( nil == waitingConnection )
        {
            if( NO == [self generateVendingConnection] )
            {
                NSLog(@"FetcherController couldn't create vending connection.");
            }
        }
        else
        {
            if( ![waitingConnection isValid] )
            {
                [waitingConnection release];
                waitingConnection = nil;
            }
        }
        NS_HANDLER
            NSLog(@"Got Exception during generation of new vended Connection: %@",[localException reason]);
        NS_ENDHANDLER

        if( CONDITION_QUEUE_NOT_EMPTY == [workQueueLock condition] )
        {
            //NSLog(@"Fetcher got work");
            if(! [self workOnQueue] )
            {
                NS_DURING
                [runLoop runMode:NSConnectionReplyMode
                    beforeDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
                NS_HANDLER
                    NSLog(@"Got Exception during RunLoop run: (1) %@",[localException reason]);
                NS_ENDHANDLER
            }
        }
        else
        {
            //NSLog(@"Fetcher waits for work");
            NS_DURING
            [runLoop runMode:NSConnectionReplyMode
                  beforeDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
            NS_HANDLER
                    NSLog(@"Got Exception during RunLoop run: (2) %@",[localException reason]);
            NS_ENDHANDLER
        }

        if( NSOrderedDescending == [(NSDate *)[NSDate date] compare:nextPingDate] )
        {
            NS_DURING
                [self pingRemoteHosts];
            NS_HANDLER
                NSLog(@"Got Exception during ping run: %@",[localException reason]);
            NS_ENDHANDLER
            [nextPingDate release];
            nextPingDate = [[NSDate dateWithTimeIntervalSinceNow:5.0] retain];
        }
        [runLoopAutoreleasePool release];

        NS_HANDLER
            NSLog(@"Got Exception outsite everything: %@",[localException reason]);
        NS_ENDHANDLER
    }

    [pool release];
}



- (BOOL)generateVendingConnection;
{
    NSConnection *intermediateWaitingConnection = [[[NSConnection alloc] init] autorelease];

    [intermediateWaitingConnection setRootObject:self];
    [intermediateWaitingConnection setDelegate:self];
    [intermediateWaitingConnection setRequestTimeout:REMOTE_REQUEST_TIME];
    [intermediateWaitingConnection setReplyTimeout:REMOTE_REPLY_TIME];
    [intermediateWaitingConnection setIndependentConversationQueueing:YES];

    if( NO == [intermediateWaitingConnection registerName:connectionName] )
    {
        NSLog(@"Can't create connection server with Name:%@",connectionName);
        return NO;
    }
    waitingConnection = [intermediateWaitingConnection retain];
    return YES;
}



- (void)addFetcher:(Fetcher *)distantObject;
{
    NSMutableDictionary	*fetcherDictionary;
    NSConnection	*newConnection;
    NSNumber		*badgeNumber;
    NSEnumerator 	*badgeNumberEnumerator;
    NSMutableArray	*badgeNumbersToRemoveArray;

    fetcherDictionary = [NSMutableDictionary dictionary];
    badgeNumbersToRemoveArray = [NSMutableArray array];
    newConnection = [(NSDistantObject *)distantObject connectionForProxy];
    
    if( ! [intermediateConnectionDictionary count] )
    {
        NSLog(@"add Fetcher - waiting for noone.");
        [[newConnection sendPort] invalidate];
        [[newConnection receivePort] invalidate];
        return;
    }

    badgeNumberEnumerator = [intermediateConnectionDictionary keyEnumerator];
    while( (badgeNumber = [badgeNumberEnumerator nextObject]) )
    {
        NSMutableArray	*connectionArray;

        connectionArray = [intermediateConnectionDictionary objectForKey:badgeNumber];
        if( newConnection ==  [connectionArray objectAtIndex:1] )
        {
            if( [usedConnectionDictionary count] >= MAXIMUM_CONNECTIONS )
            {
                NSLog(@"add Fetcher - connection rejected.");					// garbage get's collected via ping
                return;
            }
            NSLog(@"add Fetcher - connection accepted");
            [fetcherDictionary setObject:badgeNumber forKey:@"badgeNumber"];
            [connectionArray addObject:fetcherDictionary];
            [usedConnectionDictionary setObject:connectionArray forKey:badgeNumber];
            [badgeNumbersToRemoveArray addObject:badgeNumber];
        }
    }
    if( 0 == [badgeNumbersToRemoveArray count] )
    {
        NSLog(@"got connection from invalid source");
        [[newConnection sendPort] invalidate];
        [[newConnection receivePort] invalidate];
        return;
    }
    assert(1 == [badgeNumbersToRemoveArray count] );
    [intermediateConnectionDictionary removeObjectsForKeys:badgeNumbersToRemoveArray];
    
    [fetcherDictionary setObject:@"intermediateFetcher" forKey:@"hostname"];
    [fetcherDictionary setObject:[NSNumber numberWithInt:0] forKey:@"availableConnections"];
    
    [fetcherDictionary setObject:[NSDate date] forKey:@"lasttimeaccessed"];
    [fetcherDictionary setObject:[NSNumber numberWithInt:INITIAL_PONGCOUNT] forKey:@"pongcount"];
    [remoteFetchersSortedArray addObject:fetcherDictionary];

    assert([remoteFetchersSortedArray count]==[usedConnectionDictionary count]);

    NS_DURING        
        [distantObject setUserAgentName:[hooverController userAgentName]];
        [distantObject setUserAgentMail:[hooverController userAgentMail]];
        if([hooverController httpProxy])
            [distantObject setHttpProxy:[hooverController httpProxy]];

        [fetcherDictionary setObject:[NSNumber numberWithInt:[distantObject availableConnections]] forKey:@"availableConnections"];
        [fetcherDictionary setObject:distantObject forKey:@"distantObject"];
        [fetcherDictionary setObject:[distantObject hostname] forKey:@"hostname"];
        [(NSDistantObject *)distantObject setProtocolForProxy:@protocol(FetcherProtocol)];

        #if DEBUG
        NSLog(@"Added Fetcher from host:%@",[fetcherDictionary objectForKey:@"hostname"]);
        #endif
    NS_HANDLER
        if( [[localException name] isEqual:@"NSInvalidReceivePortException"]
            || [[localException name] isEqual:@"NSInvalidSendPortException"]
            || [[localException name] isEqual:@"NSInternalInconsistencyException"]
            || [[localException name] isEqual:@"NSObjectInaccessibleException"]
            || [[localException name] isEqual:@"NSObjectNotAvailableException"]
            || [[localException name] isEqual:@"NSDestinationInvalidException"]
            || [[localException name] isEqual:@"NSPortTimeoutException"] )
        {
            NSLog(@"Exception:%@ - removed incoming fetcher(1)",[localException reason]);
            [self fetcherDidDie:fetcherDictionary];
        }
        else
        {
            NSLog(@"Did not catch exception1:%@",[localException reason]);
            [localException raise];
        }
    NS_ENDHANDLER
}



- (BOOL)fetchLocalUrl:(NSMutableDictionary *)url;
{
    [workQueueLock lock];
    if( MAXIMUM_QUEUESIZE < [workQueue count] )
    {
        [workQueueLock unlockWithCondition:CONDITION_QUEUE_NOT_EMPTY];
        return NO;
    }
    [workQueue addObject:url];
    [workQueueLock unlockWithCondition:CONDITION_QUEUE_NOT_EMPTY];

    return YES;
}



- (BOOL)workOnQueue;
{
    NSMutableDictionary	*fetcherDictionary;
    NSMutableDictionary	*url;
    NSString		*urlUniqueName;
    int		   	available;

CONNECTIONLOG(@"Working on the queue")

    [workQueueLock lock];
   
    if( ! (fetcherDictionary = [remoteFetchersSortedArray lastObject]) )
    {
        NSLog(@"No Fetchers available. ( %d urls in progress )",[fetcherWorkDictionary count]);
        [workQueueLock unlockWithCondition:[workQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
        return NO;
    }
    if( 0 == (available = [[fetcherDictionary objectForKey:@"availableConnections"] intValue]) )
    {
        NSLog(@"All fetchers busy. ( %d urls in progress )",[fetcherWorkDictionary count]);
        [workQueueLock unlockWithCondition:[workQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
        return NO;
    }
    if( ! (url = [workQueue objectAtIndex:0]) )
    {
        NSLog(@"No Work in queue but work on queue called");
        [workQueueLock unlockWithCondition:[workQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
        return NO;
    }

    urlUniqueName = [NSString stringWithFormat:@"%@:%@:%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]];

    [fetcherWorkDictionary setObject:fetcherDictionary forKey:urlUniqueName];
    [fetcherDictionary setObject:url forKey:urlUniqueName];
    [workQueue removeObjectAtIndex:0];
    [workQueueLock unlockWithCondition:[workQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
    
    [fetcherDictionary setObject:[NSNumber numberWithInt:available-1] forKey:@"availableConnections"];

    assert([remoteFetchersSortedArray count]==[usedConnectionDictionary count]);					
    [remoteFetchersSortedArray removeObject:fetcherDictionary];
    [remoteFetchersSortedArray addObject:fetcherDictionary];				// it's always in the in usedConnectionDictionary
    assert([remoteFetchersSortedArray count]==[usedConnectionDictionary count]);					
        
    NSLog(@"Fetching from %@ %@",[fetcherDictionary objectForKey:@"hostname"],urlUniqueName);
    NS_DURING
        [[fetcherDictionary objectForKey:@"distantObject"] fetchUrl:url];
        [fetcherDictionary setObject:[NSDate date] forKey:@"lasttimeaccessed"];
        [fetcherDictionary setObject:[NSNumber numberWithInt:INITIAL_PONGCOUNT] forKey:@"pongcount"];
    NS_HANDLER
        if( [[localException name] isEqual:@"NSInvalidReceivePortException"]
            || [[localException name] isEqual:@"NSInvalidSendPortException"]
            || [[localException name] isEqual:@"NSInternalInconsistencyException"]
            || [[localException name] isEqual:@"NSObjectInaccessibleException"]
            || [[localException name] isEqual:@"NSObjectNotAvailableException"]
            || [[localException name] isEqual:@"NSDestinationInvalidException"]
            || [[localException name] isEqual:@"NSPortTimeoutException"] )
        {
            NSLog(@"Exception:%@ - (3) fetcher on host %@",[localException name],[fetcherDictionary objectForKey:@"hostname"]);
            [self fetcherDidDie:fetcherDictionary];
        }
        else
        {
            NSLog(@"Did not catch exception:%@",[localException reason]);
            [localException raise];
        }
    NS_ENDHANDLER

    return YES;
}




- (void)pingRemoteHosts;
{
    NSMutableDictionary	*fetcherDictionary;
    NSMutableDictionary	*sleepyFetcherDictionary = nil;
    NSString		*fetcherName;
    NSEnumerator	*objectEnumerator;
    NSDate		*pastDate;

CONNECTIONLOG(@"Ping1")
        
    pastDate = [NSDate dateWithTimeIntervalSinceNow:-5.0];

    if( [intermediateConnectionDictionary count] )
    {
        NSNumber		*badgeNumber;
        NSEnumerator 		*badgeNumberEnumerator;
        NSMutableArray		*badgeNumbersToRemoveArray = [NSMutableArray array];
        
        badgeNumberEnumerator = [intermediateConnectionDictionary keyEnumerator];
        while( badgeNumber = [badgeNumberEnumerator nextObject] )
        {
            NSArray	*connectionArray = [intermediateConnectionDictionary objectForKey:badgeNumber];
            
            if( NSOrderedDescending ==  [pastDate compare:(NSDate *)[connectionArray objectAtIndex:2]] )
            {
               NSLog(@"Incoming connection never tried to add itself.");
               [badgeNumbersToRemoveArray addObject:badgeNumber];

               [[[connectionArray objectAtIndex:1] sendPort] invalidate];
               [[[connectionArray objectAtIndex:1] receivePort] invalidate];
               [[[connectionArray objectAtIndex:0] sendPort] invalidate];
               [[[connectionArray objectAtIndex:0] receivePort] invalidate];
          }
        }
        NSLog(@"Removed %d invalid intermediate connections.",[badgeNumbersToRemoveArray count]);
        [intermediateConnectionDictionary removeObjectsForKeys:badgeNumbersToRemoveArray];
    }

CONNECTIONLOG(@"Ping 2")

    if( ! [remoteFetchersSortedArray count] )
    {
        NSLog(@"No Fetchers available");
        return;
    }

    objectEnumerator = [remoteFetchersSortedArray objectEnumerator];
    while( fetcherDictionary = [objectEnumerator nextObject] )
    {
        if( NSOrderedDescending == [pastDate compare:(NSDate *)[fetcherDictionary objectForKey:@"lasttimeaccessed"]] )
        {
            if(nil == sleepyFetcherDictionary)
            {
                sleepyFetcherDictionary = fetcherDictionary;
            }
            else
            {
                if( NSOrderedDescending == [(NSDate *)[sleepyFetcherDictionary objectForKey:@"lasttimeaccessed"] compare:(NSDate *)[fetcherDictionary objectForKey:@"lasttimeaccessed"]] )
                    sleepyFetcherDictionary = fetcherDictionary;
            }
        }
    }
    if( nil == sleepyFetcherDictionary ) return;

    fetcherName = [sleepyFetcherDictionary objectForKey:@"hostname"];
    NSLog(@"Ping %@ ",fetcherName);

    NS_DURING
        [[sleepyFetcherDictionary objectForKey:@"distantObject"] ping];
        [sleepyFetcherDictionary setObject:[NSDate date] forKey:@"lasttimeaccessed"];
        [sleepyFetcherDictionary setObject:[NSNumber numberWithInt:INITIAL_PONGCOUNT] forKey:@"pongcount"];
    NS_HANDLER
        if( [[localException name] isEqual:@"NSPortTimeoutException"] )
        {
            if( ![[sleepyFetcherDictionary objectForKey:@"pongcount"] intValue] )
            {
                NSLog(@"Removing sleeping Fetcher %@",fetcherName);
                [self fetcherDidDie:sleepyFetcherDictionary];
            }
            else
            {
                int i = [[sleepyFetcherDictionary objectForKey:@"pongcount"] intValue];
                NSLog(@"Fetcher %@ is sleepy (sleepcount %d)",fetcherName,i);
                [sleepyFetcherDictionary setObject:[NSNumber numberWithInt:i-1] forKey:@"pongcount"];
            }
        }
        else
            if( [[localException name] isEqual:@"NSInvalidReceivePortException"]
                || [[localException name] isEqual:@"NSInvalidSendPortException"]
                || [[localException name] isEqual:@"NSInternalInconsistencyException"]
                || [[localException name] isEqual:@"NSObjectInaccessibleException"]
                || [[localException name] isEqual:@"NSObjectNotAvailableException"]
                || [[localException name] isEqual:@"NSDestinationInvalidException"] )
            {
                NSLog(@"Exception:%@ - (ping3) fetcher on host %@",[localException name],fetcherName);
                [self fetcherDidDie:sleepyFetcherDictionary];
            }
            else
            {
                NSLog(@"Did not catch exception:%@",[localException reason]);
                [localException raise];
            }
    NS_ENDHANDLER
}



- (void)retrievedUrl:(bycopy NSMutableDictionary *)url;
{
    NSMutableDictionary	*fetcherDictionary;
    NSString		*urlUniqueName;
    int		    	available;

    urlUniqueName = [NSString stringWithFormat:@"%@:%@:%@",[url objectForKey:@"host"]
        ,[url objectForKey:@"port"],[url objectForKey:@"path"]];

    if( !(fetcherDictionary = [fetcherWorkDictionary objectForKey:urlUniqueName]) )
    {
        NSLog(@"Got unwanted url.");
        return;
    }
    #if DEBUG
        NSLog(@"%@ retrieved URL %@",[fetcherDictionary objectForKey:@"hostname"],urlUniqueName);
    #endif
    available = [[fetcherDictionary objectForKey:@"availableConnections"] intValue];
    [fetcherDictionary setObject:[NSNumber numberWithInt:available+1] forKey:@"availableConnections"];
    [fetcherDictionary setObject:[NSDate date] forKey:@"lasttimeaccessed"];
    [fetcherDictionary setObject:[NSNumber numberWithInt:INITIAL_PONGCOUNT] forKey:@"pongcount"];


    if( ![remoteFetchersSortedArray containsObject:fetcherDictionary] )
    {
        NSLog(@"Retrieved url from old fetcher - accepted");
    }
    else
    {
        [remoteFetchersSortedArray removeObject:fetcherDictionary];
        [remoteFetchersSortedArray addObject:fetcherDictionary];			// it's always in the in usedConnectionDictionary
    }

    [fetcherWorkDictionary removeObjectForKey:urlUniqueName];
    [fetcherDictionary removeObjectForKey:urlUniqueName];
    [hooverController retrievedUrl:url];
}



- (BOOL)connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnection;
{
    static	int	badgenumber=0;
    
    if( ! [newConnection isValid] )
    {
        NSLog(@"Got invalid Connection - continueing");
        [waitingConnection release];
        waitingConnection=nil;
        return NO;
    }
    
    if( waitingConnection != parentConnection )
    {
        NSLog(@"connection should make connection - did not find the parent in waiting connections - ignoring");
        [waitingConnection release];
        waitingConnection=nil;
        return NO;
    }

    if( [usedConnectionDictionary count] <= MAXIMUM_CONNECTIONS )
    {
        NSLog(@"Incoming connection accepted.");
        if( ! [parentConnection registerName:nil] )							// unregister Network Connection
        {
            NSLog(@"Cant unregister name");
        }
        [intermediateConnectionDictionary setObject:[NSMutableArray arrayWithObjects:parentConnection,newConnection,[NSDate date],nil]
                                             forKey:[NSNumber numberWithInt:badgenumber++]];
        [waitingConnection release];
        waitingConnection=nil;
        return YES;
    }
    
    NSLog(@"Incoming connection rejected.");
    [waitingConnection release];
    waitingConnection=nil;
    return NO;
}



- (void)fetcherDidDie:(NSMutableDictionary *)deadFetcherDictionary;
{
    NSEnumerator	*urlEnumerator;
    NSString		*urlUniqueName;
    NSNumber		*badgeNumber;
    NSArray		*urlsInWorkArray;
    NSArray		*connectionArray;
    int			count=0;

    badgeNumber = [deadFetcherDictionary objectForKey:@"badgeNumber"];
    if( ! ( connectionArray =  [usedConnectionDictionary objectForKey:badgeNumber] ))
    {
        NSLog(@"Notification about unknown Fetcher.");
        exit(1);
    }

CONNECTIONLOG(@"Fetcher died 1")

    urlsInWorkArray = [fetcherWorkDictionary allKeysForObject:deadFetcherDictionary];
    urlEnumerator = [urlsInWorkArray objectEnumerator];
    [workQueueLock lock];
    while( urlUniqueName = [urlEnumerator nextObject] )
    {
        [workQueue addObject:[deadFetcherDictionary objectForKey:urlUniqueName]];
        count++;
    }
    [workQueueLock unlockWithCondition:[workQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
    NSLog(@"Reinserted %d urls.",count);
    [fetcherWorkDictionary removeObjectsForKeys:urlsInWorkArray];

    NS_DURING
    [[[connectionArray objectAtIndex:1] sendPort] invalidate];
    [[[connectionArray objectAtIndex:1] receivePort] invalidate];
    [[[connectionArray objectAtIndex:0] sendPort] invalidate];
    [[[connectionArray objectAtIndex:0] receivePort] invalidate];
    NS_HANDLER
        NSLog(@"Got Exception during 'kicking the dead' process: %@",[localException reason]);
    NS_ENDHANDLER

    
    
    NS_DURING
        [usedConnectionDictionary removeObjectForKey:badgeNumber];
    NS_HANDLER
        NSLog(@"Got Exception during burying(1) process: %@",[localException reason]);
    NS_ENDHANDLER

    NS_DURING
    {
        int i = [remoteFetchersSortedArray indexOfObject:deadFetcherDictionary];
        NSLog(@"i = %d",i);
        [remoteFetchersSortedArray removeObjectAtIndex:i];
    }
    NS_HANDLER
        NSLog(@"Got Exception during burying(2) process: %@",[localException reason]);
    NS_ENDHANDLER

CONNECTIONLOG(@"Fetcher died 2")
    NSLog(@"Done with connection cleanup.");
    return;
}



@end

