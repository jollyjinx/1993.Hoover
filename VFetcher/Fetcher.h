/* Fetcher.h created by jolly on Fri 07-Mar-1997 */

#import <Foundation/Foundation.h>
#import "ThreadController.h"
#import "FetcherController.h"

@class Worker;

@interface Fetcher : NSObject
{
    FetcherController	*hooverObject;
    ThreadController 	*threadController;
    NSMutableArray	*availableWorkers;

    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
    int   	   	availableconnections;
}

- (Fetcher *)initWithMaximumConnections:(int)maxcon hooverObject:(FetcherController *)dObject;

- (void)workerWantsWork:(Worker *)proxyWorker;
- (void)detachWorkingThreads;

- (void)fetchUrl:(bycopy NSMutableDictionary *)url;
- (void) retrievedUrl:(NSMutableDictionary *)url withWorker:(Worker *)proxyWorker;

- (void) setUserAgentName:(bycopy NSString*)uaName;
- (bycopy NSString*)userAgentName;
- (void) setUserAgentMail:(bycopy NSString*)uaMail;
- (bycopy NSString*)userAgentMail;
- (void) setHttpProxy:(bycopy NSMutableDictionary *)uaProxy;
- (bycopy NSMutableDictionary *)httpProxyDictionary;

- (bycopy NSString *)hostname;
- (int)availableConnections;
- (void) ping;
@end
