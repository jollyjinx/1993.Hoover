/* HooverController.h created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#import "RobotScanner.h"
#import "FetcherController.h"


@interface HooverController : NSObject
{
    GDBMCache	  		*gdbmCache;

    MTQueue			*receivedUrlsQueue;

    FetcherController		*fetcherController;
    
    NSMutableDictionary		*allSitesDictionary;
    DatedQueue			*allSitesDatedQueue;
    NSLock			*siteLock;

    BOOL			stayonsites;
    BOOL			allpathsallowed;
}

- (id)initWithConfiguration:(NSDictionary *)configurationDictionary;

- (void)putWorkInSendingUrlsQueue;

- (void)runTheRetrievingThread;

- (void)workOnReceivedUrlsQueue;

- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl;
- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl freePath:(BOOL)freepath;

// Remote Methods
- (void)retrievedUrl:(NSMutableDictionary *)url;

// Signals
- (void)save;
- (void)showCurrentStatus;
@end
