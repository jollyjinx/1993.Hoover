/* RobotScanner.h created by jolly on Tue 04-Mar-1997 */

#import <Foundation/Foundation.h>
#import "RobotScanner.h"

@interface RobotScanner : NSObject
{
    NSArray	*includedSiteArray;
    NSArray	*excludedSiteArray;
    NSArray	*includedPathArray;
    NSArray	*excludedPathArray;
}

- (RobotScanner *)initWithUrl:(NSMutableDictionary *)url userAgentName:(NSString *)uaName;
- (RobotScanner *)initWithContentsOfGeneralConfiguration:(NSDictionary *)generalDictionary;
- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;

- (BOOL)includedPath:(NSString *)path;
- (BOOL)excludedPath:(NSString *)path;
- (BOOL)includedSite:(NSString *)site;
- (BOOL)excludedSite:(NSString *)site;


@end
