
#import <Foundation/Foundation.h>
#import "Queue.h"

@interface FileWriter : NSObject
{
    Queue	*writeToFileQueue;
}

- (id)init;
- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;

- (void) _runTheWriteToFileLoop;

@end