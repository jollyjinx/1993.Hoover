
#import <Foundation/Foundation.h>
#import <HooverFramework/MTQueue.h>

@interface FileWriter : NSObject
{
    MTQueue	*writeToFileQueue;
}

- (id)init;
- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;

- (void) _runTheWriteToFileLoop;

@end
