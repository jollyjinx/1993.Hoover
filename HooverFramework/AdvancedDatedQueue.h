
#import <Foundation/Foundation.h>
#import "RedBlackTree.h"

@interface AdvancedDatedQueue : NSObject
{
    NSConditionLock	*queueLock;
    NSLock		*singlePopLock;
    RedBlackTree 	*queueRedBlackTree;
    NSMutableDictionary	*queueDictionary;
}
- pop;
- popBeforeDate:(NSDate *)endDate;
- (void) push:(id)anObject withDate:(NSDate *)date;
- (BOOL)containsObject:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeAllObjects;

- (unsigned int) count;

@end

