/* FetcherController.m created by jolly on Thu 06-Mar-1997 */

#import "FetcherController.h"
//#import <OmniNetworking/OmniNetworking.h>

#define	CONDITION_NO_VENDED_CONNECTION	0
#define	CONDITION_ONE_VENDED_CONNECTION	1

#define	CONDITION_NO_FETCHERS_AVAILABLE	0
#define	CONDITION_FETCHER_AVAILABLE	1

#define HOOVER_PORT 12345

#define MAXIMUM_CONNECTIONS 20




@implementation FetcherController


- (void)dealloc;
{
    NSLog(@"FetcherController: got deallocated");
    
    [distributedFetchersSortedArray release];
    [distributedFetchersWorkDictionary release];
    [distributedFetchersSortedArrayLock release];

    [workQueue release];
    [hooverController release];
    
    [super dealloc];
}


- (FetcherController *)init;
{    
    [super init];

    distributedFetchersSortedArray = [[SortedArray alloc] init];
    distributedFetchersWorkDictionary = [[NSMutableDictionary alloc] init];
    distributedFetchersSortedArrayLock = [[NSConditionLock alloc] initWithCondition:CONDITION_NO_FETCHERS_AVAILABLE];
    
    workQueue = [[MTQueue alloc] init];

    return self;
}


- (void)runWithHooverController:(HooverController *)hc;
{
    NSAutoreleasePool	*outerPool = [[NSAutoreleasePool alloc] init];
    hooverController = [hc retain];

    [NSThread detachNewThreadSelector:@selector(createVendingConnection)
                             toTarget:self
                           withObject:nil];
    

    while( 1 )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        DFetcher		*dFetcher;
        NSMutableDictionary	*url;
        NSString		*urlUniqueName;
        
        url = [workQueue pop];
        #if DEBUG
            NSLog(@"FetcherController: workQueue has %d items.",[workQueue count]);
            NSLog(@"FetcherController: popped %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
        #endif

        [distributedFetchersSortedArrayLock lockWhenCondition:CONDITION_FETCHER_AVAILABLE];
        dFetcher = [distributedFetchersSortedArray lastObject];
        urlUniqueName= [NSString stringWithFormat:@"%@:%@:%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]];
        [[distributedFetchersWorkDictionary objectForKey:[dFetcher key]] setObject:url forKey:urlUniqueName];
        #if DEBUG
            NSLog(@"FetcherController: using host: %@ ( %3.0f  %% free ) of %d Fetchers",[dFetcher hostName],[dFetcher percentage]*100.0,[distributedFetchersSortedArray count]);
        #endif
        [dFetcher fetchUrl:url];
        [distributedFetchersSortedArray adjustObjectIdenticalTo:dFetcher];
        [distributedFetchersSortedArrayLock unlockWithCondition:
((float)[[distributedFetchersSortedArray lastObject] percentage]>0.0)?CONDITION_FETCHER_AVAILABLE:CONDITION_NO_FETCHERS_AVAILABLE];

        [pool release];
    }
    [outerPool release];
}


- (void)createVendingConnection;							
{
    NSAutoreleasePool	*outerPool	= [[NSAutoreleasePool alloc] init];
    HFUDPSocket		*vendingPort	= [HFUDPSocket socket];

    [vendingPort setLocalPortNumber:HOOVER_PORT allowingAddressReuse: YES];
    if( 0 )
    {
        NSLog(@"Can't create vending UDP socket with portnumber %d",HOOVER_PORT);
        exit(1);
    }
    
    while(1)
    {
        NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
        NSData			*data;

        NSLog(@"Waiting for incoming packet.");
        data = [vendingPort readData];
        if( [data length] )
        {
            DFetcher *dFetcher = [[DFetcher alloc] initWithFetcherController:self];
            [NSThread detachNewThreadSelector:@selector(initiateConnection:)
                                     toTarget:dFetcher
                                   withObject:data];
            [dFetcher release];
        }

        [innerPool release];
    }
    [outerPool release];
}


- (void)fetchLocalUrl:(NSMutableDictionary *)url;
{
    [workQueue push:url];
}

- (unsigned int)count;
{
    return [workQueue count];
}

- (void)retrievedUrl:(NSMutableDictionary *)url dFetcher:(DFetcher *)dFetcher;
{
    NSString	*urlUniqueName = [NSString stringWithFormat:@"%@:%@:%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]];

    [distributedFetchersSortedArrayLock lock];
    [[distributedFetchersWorkDictionary objectForKey:[dFetcher key]] removeObjectForKey:urlUniqueName];
    [distributedFetchersSortedArray adjustObjectIdenticalTo:dFetcher];
    [distributedFetchersSortedArrayLock unlockWithCondition:CONDITION_FETCHER_AVAILABLE];
    [hooverController retrievedUrl:url];
}





- (void)fetcherLogon:(DFetcher *)dFetcher;
{
    [distributedFetchersSortedArrayLock lock];
    [distributedFetchersSortedArray addObject:dFetcher];
    [distributedFetchersWorkDictionary setObject:[NSMutableDictionary dictionary] forKey:[dFetcher key]];
    [distributedFetchersSortedArrayLock unlockWithCondition:CONDITION_FETCHER_AVAILABLE];
    NSLog(@"Fetcher got born.");
}


- (void)fetcherLogoff:(DFetcher *)dFetcher reason:(NSString *)errorString;
{
    NSMutableDictionary	*workDictionary;
    NSMutableDictionary	*url;
    NSEnumerator		*objectEnumerator;
    
    [distributedFetchersSortedArrayLock lock];

    workDictionary = [distributedFetchersWorkDictionary objectForKey:[dFetcher key]];
    NSLog(@"Sending %d urls back from %@.",[workDictionary count],[dFetcher hostName]);
    objectEnumerator = [workDictionary objectEnumerator];
    while( url = [objectEnumerator nextObject] )
    {
        [url setObject:@"invalid" forKey:@"status"];
        [url setObject:errorString forKey:@"errorreason"];
        [hooverController retrievedUrl:url];
    }

    [distributedFetchersSortedArray removeObjectIdenticalTo:dFetcher];
    [distributedFetchersWorkDictionary removeObjectForKey:[dFetcher key]];
    if( ![distributedFetchersSortedArray count])
    {
        [distributedFetchersSortedArrayLock unlockWithCondition:CONDITION_NO_FETCHERS_AVAILABLE];
        return;
    }
    [distributedFetchersSortedArrayLock unlockWithCondition: ((float)[[distributedFetchersSortedArray lastObject] percentage]>0.0)?CONDITION_FETCHER_AVAILABLE:CONDITION_NO_FETCHERS_AVAILABLE];
}       

@end

