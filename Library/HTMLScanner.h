/* HTMLScanner.h created by jolly on Mon 03-Mar-1997 */

#import <Foundation/Foundation.h>
#import "Categories.h"

@interface HTMLScanner : NSObject
{

}

+ (NSMutableDictionary *)getDictionaryFromURL:(NSString*)urlString baseUrl:(NSMutableDictionary *)baseUrl;
 
+ (NSString *)normalizePath:(NSString *)pathString;

+ (NSString *) encodeISOLatin1:(NSString *)htmlString;
+ (NSString *) decodeISOLatin1:(NSString *)htmlString;

@end
