/* HooverController.h created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>
#import <EOAccess/EOAccess.h>
#import <HooverFramework/HooverFramework.h>

#import "FetcherController.h"


@interface HooverController : NSObject
{
    AdvancedDatedQueue		*allSitesDatedQueue;
    MTQueue			*receivedUrlsQueue;
    NSMutableDictionary		*sitesInformationDictionary;
    NSMutableDictionary		*fetchedPagesDictionary;
    FetcherController		*fetcherController;

//    EOEditingContext		*eoEditingContext;
    NSLock			*eofLock;
}

- (id)initWithConfiguration:(NSDictionary *)configurationDictionary;

- (void)stageWorkLoop;
- (void)runTheRetrievingThread;

// Remote Methods
- (void)retrievedUrl:(NSMutableDictionary *)url;

// Signals
- (void)save;
- (void)showCurrentStatus;
@end
