
#import <Foundation/Foundation.h>
#import "MTQueue.h"

@interface FileWriter : NSObject
{
    MTQueue		*writeToFileQueue;
    NSString		*fileNamePrefix;
    unsigned int	urlsperfile;
}

- (id)init;
- (id)initWithFilenamePrefix:(NSString *)filenamePrefix urlsPerFile:(int)number;

- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;

- (void) _runTheWriteToFileLoop;

@end