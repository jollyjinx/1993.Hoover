/* HooverController.h created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>

#import "SortedArray.h"
#import "HTMLScanner.h"
#import "RobotScanner.h"
#import "FetcherController.h"
#import "JPPL.h"

#define SERVER_WAITINGFOR_REPLY		0
#define SERVER_PROCESSING_REPLY		1
#define FETCHER_PROCESSING_REQUEST	2
#define	FETCHER_CLIENT_DIED		3


@interface HooverController : NSObject
{
    JPPL		*propertyList;

    NSConditionLock	*writeToFileLock;
    NSMutableArray	*writeToFileQueue;
    
    NSConditionLock	*receivedUrlsQueueLock;	
    NSMutableArray	*receivedUrlsQueue;
    NSMutableArray	*sendingUrlsQueue;
    FetcherController	*fetcherController;
    
    NSMutableDictionary	*allSitesDictionary;
    SortedArray		*allSitesSortedArray;

    RobotScanner	*generalScanner;

    NSString		*userAgentName;
    NSString		*userAgentMail;
    NSMutableDictionary	*httpProxy;
}

- (HooverController *)initWithConfiguration:(NSDictionary *)configurationDictionary;

- (void)runTheLoop;
- (void)putWorkInSendingUrlsQueue;
- (BOOL)workOnSendingUrlsQueue;
- (void)workOnReceivedUrlsQueue;
- (void) runTheWriteToFileLoop;

- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl;
- (NSString *)userAgentName;
- (NSString *)userAgentMail;
- (NSMutableDictionary *)httpProxy;

// Remote Methods
- (void)retrievedUrl:(NSMutableDictionary *)url;


// Notifications
- (void)propertyListBecameInvalid:(NSNotification *)notificationObject;

@end
