/* DFetcher.h created by jolly on Tue 21-Oct-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

@class DFetcher,FetcherController,HooverController;

#import "DFetcher.h"
#import "HooverController.h"

@interface FetcherController : NSObject
{
    SortedArray		*distributedFetchersSortedArray;
    NSMutableDictionary	*distributedFetchersWorkDictionary;
    NSConditionLock    	*distributedFetchersSortedArrayLock;
    
    MTQueue		*workQueue;

    HooverController	*hooverController;
}

- (void)runWithHooverController:(HooverController *)hc;

- (unsigned int)count;
- (void)fetchLocalUrl:(NSMutableDictionary *)url;
- (void)retrievedUrl:(NSMutableDictionary *)url dFetcher:(DFetcher *)dFetcher;

- (void)createVendingConnection;							

- (void)fetcherLogon:(DFetcher *)dFetcher;
- (void)fetcherLogoff:(DFetcher *)dFetcher reason:(NSString *)errorString;


@end
