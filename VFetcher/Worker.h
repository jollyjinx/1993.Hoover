/* Worker.h created by jolly on Wed 14-May-1997 */

#import <Foundation/Foundation.h>

#import "Fetcher.h"
#import "ThreadController.h"

@interface Worker : NSObject
{
    Fetcher		*fetcherObject;
    BOOL		agentCacheActive;
    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
}

- (void)runWithController:(ThreadController *)tc;

- (oneway void)retrieveUrl:(NSMutableDictionary *)url;
- (void)parseHTTPResponse:(NSData *)httpData intoURL:(NSMutableDictionary *)url;

@end

