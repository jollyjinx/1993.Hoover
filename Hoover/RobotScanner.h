/* RobotScanner.h created by jolly on Tue 04-Mar-1997 */

#import <Foundation/Foundation.h>

@interface RobotScanner : NSObject <NSCoding>
{
    NSArray	*includedPathArray;
    NSArray	*excludedPathArray;
}

+ (RobotScanner *)robotScannerWithUrl:(NSMutableDictionary *)url;
- (RobotScanner *)initWithUrl:(NSMutableDictionary *)url;

- (NSArray *)unwantedPaths:(NSMutableDictionary *)dictionaryOfUrls;
- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;

- (BOOL)includedPath:(NSString *)path;
- (BOOL)excludedPath:(NSString *)path;


@end
