/* RobotScanner.h created by jolly on Tue 04-Mar-1997 */

#import <Foundation/Foundation.h>

@interface RobotScanner : NSObject <NSCoding>
{
    NSArray	*includedPathArray;
    NSArray	*excludedPathArray;
}

+ (RobotScanner *)robotScannerWithUrl:(NSMutableDictionary *)url;
+ (RobotScanner *)robotScannerWithDescription:(NSString *)aDescription;

- (RobotScanner *)initWithUrl:(NSMutableDictionary *)url;
- (RobotScanner *)initWithIncludedPathArray:(NSMutableArray *)incArray excludedPathArray:(NSMutableArray *)excArray;

- (NSArray *)unwantedPaths:(NSMutableDictionary *)dictionaryOfUrls;
- (BOOL)urlIsWanted:(NSDictionary *)urlToTest;

- (BOOL)includedPath:(NSString *)path;
- (BOOL)excludedPath:(NSString *)path;


@end
