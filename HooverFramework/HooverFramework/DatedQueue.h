
#import <Foundation/Foundation.h>
#import <HooverFramework/SortedArray.h>

@interface DatedQueue : NSObject
{
    NSConditionLock	*queueLock;
    NSLock		*singlePopLock;
    SortedArray 	*queueArray;
}
- pop;
- (void) push:(id)anObject withDate:(NSDate *)date;
- (unsigned int) count;

@end

