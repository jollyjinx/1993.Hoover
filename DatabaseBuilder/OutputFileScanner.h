/* OutputFileScanner.h created by jolly on Thu 12-Feb-1998 */

#import <Foundation/Foundation.h>

@interface OutputFileScanner : NSObject
{
    NSString   				*databaseName;
    NSMutableDictionary		*internalDatabase;
}

- (id)initWithContentsOfDatabase:(NSString *)aPath;
- (void)readFiles:(NSArray *)fileNameArray;
- (void)writeDatabase:(NSString *)aPath;

- (void)_addUrlToSearchlist:(NSMutableDictionary *)newUrl;

@end
