/* Worker.h created by jolly on Wed 14-May-1997 */

#import <Foundation/Foundation.h>

#import "Fetcher.h"

@interface Worker : NSObject


- (void)retrieveUrl:(NSMutableDictionary *)url
      userAgentName:(NSString *)userAgentName
      userAgentMail:(NSString *)userAgentMail
httpProxyDictionary:(NSMutableDictionary *)httpProxyDictionary
       hooverObject:(FetcherController *)hooverObject
               lock:(NSLock *)crashMachineLock;
- (void)parseHTTPResponse:(NSData *)httpData intoURL:(NSMutableDictionary *)url;

@end

