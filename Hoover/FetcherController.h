/* FetcherController.h created by jolly on Thu 06-Mar-1997 */

#import <Foundation/Foundation.h>

@class Fetcher,FetcherController,HooverController;

#import "HooverController.h"
#import "SortedArray.h"
#import "Fetcher.h"

@interface FetcherController : NSObject
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

- (void)runWithHooverController:(HooverController *)hc;

- (BOOL)generateVendingConnection;

- (void)addFetcher:(Fetcher *)distantObject;
- (BOOL)workOnQueue;
- (BOOL)fetchLocalUrl:(NSMutableDictionary *)url;
- (void)pingRemoteHosts;
- (void)retrievedUrl:(bycopy NSMutableDictionary *)url;

- (BOOL)connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnnection;
- (void)fetcherDidDie:(NSMutableDictionary *)deadFetcherDictionary;

@end
