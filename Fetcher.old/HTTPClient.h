/* HTTPClient.h created by jolly on Thu 18-Dec-1997 */

#import <Foundation/Foundation.h>

@interface HTTPClient : NSObject
{
    
}

+ (HTTPClient *)httpClient;

- (NSFileHandle *)createConnectionToHost:(NSMutableDictionary *)hostDictionary;

- (void)retrieveUrl:(NSMutableDictionary *)url;

- (NSMutableDictionary *)parseHTTPResponse:(NSData *)httpHeader;



@end
