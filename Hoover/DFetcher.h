/* DFetcher.h created by jolly on Tue 21-Oct-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>
//#import <OmniNetworking/OmniNetworking.h>

#import "FetcherController.h"

@interface DFetcher : NSObject
{
    NSNumber			*key;
    FetcherController 	*fetcherController;

    MTQueue		*stopRunningQueue;
    NSLock		*currentworkLoadLock;
    int			currentworkload;
    int			maximumworkload;

    NSString	*hostName;

    MTQueue		*sendQueue;
}
+ (NSNumber *)getNewKey;
- (NSNumber *)key;

- (DFetcher *)initWithFetcherController:(FetcherController *)fc;
+ (DFetcher *)dFetcherWithFetcherController:(FetcherController *)fc;

- (void)initiateConnection:(NSData *)data;

- (NSString *)hostName;
- (float)percentage;
- (NSComparisonResult) compare:(id)dFetcher;

- (void)fetchUrl:(NSMutableDictionary *)url;
- (void)runSendingThread:(TCPConnection *)sendPort;
- (void)runReceivingThread:(TCPConnection *)receivePort;

@end
