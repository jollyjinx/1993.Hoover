
#import <Foundation/Foundation.h>

@interface MTQueue : NSObject
{
    NSConditionLock	*queueLock;
    NSMutableArray 	*queueArray;
}
- init;
- pop;
- popDoNotBlock;
- (void) push:(id)anObject;
- (unsigned int) count;

@end
