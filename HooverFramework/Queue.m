
#import "Queue.h"

#define	QUEUE_EMPTY	0
#define	QUEUE_NOT_EMPTY	1


@implementation Queue
{
    NSConditionLock	*queueLock;
    NSMutableArray 	*queueArray;
}


- init
{
    [super init];
    
    queueLock = [[NSConditionLock alloc] initWithCondition:QUEUE_EMPTY];
    queueArray = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [queueLock release];
    [queueArray release];
    [super dealloc];
}

- pop;
{
    id	anObject;

    [queueLock lockWhenCondition:QUEUE_NOT_EMPTY];
    anObject = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_NOT_EMPTY:QUEUE_EMPTY)];
    
    return anObject;
}

- popDoNotBlock;
{
    id	anObject=nil;

    [queueLock lock];
    if([queueArray count])
    {
        anObject = [[[queueArray objectAtIndex:0] retain] autorelease];
        [queueArray removeObjectAtIndex:0];
    }
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_NOT_EMPTY:QUEUE_EMPTY)];
    
    return anObject;
}


- (void) push:(id)anObject;
{
    [queueLock lock];
    [queueArray addObject:anObject];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_NOT_EMPTY:QUEUE_EMPTY)];
}

- (unsigned int) count;
{
    return [queueArray count];
}


@end
