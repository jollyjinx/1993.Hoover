
#import <Foundation/Foundation.h>
#import <HooverFramework/SortedArray.h>

@interface AdvancedDatedQueue : NSObject
{
    NSConditionLock	*queueLock;
    NSLock		*singlePopLock;
    SortedArray 	*queueArray;
    NSMutableDictionary	*queueDictionary;
}
- pop;
- (void) push:(id)anObject withDate:(NSDate *)date;
- (BOOL)containsObject:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeAllObjects;

- (unsigned int) count;

@end

