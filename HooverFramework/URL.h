/* URL.h created by jolly on Thu 18-Feb-1999 */

#import <Foundation/Foundation.h>

@interface URL : NSObject
{

}

+ urlWithString:(NSString *)urlString;
+ urlWithString:(NSString *)urlString baseString:(NSString *)baseString;
+ urlWithString:(NSString *)urlString baseUrl:(URL *)baseUrl;

- initWithString:(NSString *)urlString;
- initWithString:(NSString *)urlString baseString:(NSString *)baseString;
- initWithString:(NSString *)urlString baseUrl:(URL *)baseUrl;

- (NSString *)description;

+ (NSString *)_encodeUndefined:(NSString *)unsafeString;
+ (NSString *)_encodeString:(NSString *)unsafeString allowedCharacterSet:(NSCharacterSet *)characterSet;
+ (NSString *)_decodeString:(NSString *)safeString;




@end
