/* Fetcher.h created by jolly on Fri 07-Mar-1997 */

#import <Foundation/Foundation.h>
#import "FetcherController.h"

@class Worker;

@interface Fetcher : NSObject
{
    FetcherController	*hooverObject;

    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
    int			availableconnections;

    NSLock		*crashMachineLock;
}


- (Fetcher *)initWithHooverObject:(FetcherController *)dObject availableConnections:(int)ac;

- (oneway void)fetchUrl:(bycopy NSMutableDictionary *)url;

- (void) setUserAgentName:(bycopy NSString*)uaName;
- (NSString*)userAgentName;
- (void) setUserAgentMail:(bycopy NSString*)uaMail;
- (NSString*)userAgentMail;
- (void) setHttpProxy:(bycopy NSMutableDictionary *)uaProxy;
- (NSMutableDictionary *)httpProxyDictionary;

- (NSString *)hostname;
- (int)availableConnections;
- (void) ping;
@end
