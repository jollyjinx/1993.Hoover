
#import <Foundation/Foundation.h>
#import "MTQueue.h"

@interface FileWriter : NSObject
{
    MTQueue	*writeToFileQueue;
}

- (id)init;
- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;

- (void) _runTheWriteToFileLoop;

@end