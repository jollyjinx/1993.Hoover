
#import <Foundation/Foundation.h>

@interface GeneralScanner : NSObject
{
    NSArray	*includedSiteArray;
    NSArray	*excludedSiteArray;
    NSArray	*includedPathArray;
    NSArray	*excludedPathArray;
    NSMutableDictionary	*excludedExtensionsDictionary;
}

- (id)initWithConfiguration:(NSDictionary *)generalDictionary;

- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;

- (BOOL)includedPath:(NSString *)path;
- (BOOL)excludedPath:(NSString *)path;

- (BOOL)includedSite:(NSString *)site;
- (BOOL)excludedSite:(NSString *)site;

- (BOOL)excludedExtension:(NSString *)path;


@end


