
#import "DatedQueue.h"

#define	QUEUE_IS_UNKNOWN	0
#define QUEUE_IS_KNOWN		1

@interface DatedQueueLeaf : NSObject
{
    id		contentObject;
    NSDate	*contentDate;
}
- initWithObject:(id)anObject andDate:(NSDate *)aDate;
- (NSComparisonResult)compare:(id)anObject;
- contentObject;
- (NSDate *) contentDate;
@end

@implementation DatedQueueLeaf
{
    id		contentObject;
    NSDate	*contentDate;
}

- (void)dealloc;
{
    [contentObject release];
    [contentDate release];
    [super dealloc];
}

- initWithObject:(id)anObject andDate:(NSDate *)aDate;
{
    [super init];

    contentObject = [anObject retain];
    contentDate = [aDate retain];
    
    return self;
}

- (NSComparisonResult)compare:(id)anObject;
{
    return [contentDate compare:(NSDate *)[anObject contentDate]];
}

- contentObject;
{
    return contentObject;
}
- (NSDate *) contentDate;
{
    return contentDate;
}
@end


@implementation DatedQueue
{
    NSConditionLock	*queueLock;
    NSLock		*singlePopLock;
    SortedArray 	*queueArray;
}


- init
{
    [super init];
    queueLock = [[NSConditionLock alloc] initWithCondition:QUEUE_IS_KNOWN];
    singlePopLock = [[NSConditionLock alloc] init];
    queueArray = [[SortedArray alloc] init];
    return self;
}

- (void) dealloc
{
    [queueLock release];
    [singlePopLock release];
    [queueArray release];
    [super dealloc];
}


- pop;
{
    NSDate		*aDate = [NSDate distantFuture];
    DatedQueueLeaf	*aLeaf;
    
    [singlePopLock lock];
    [queueLock lock];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];
    do
    {
        if( [queueLock lockWhenCondition:QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[queueArray objectAtIndex:0] contentDate];
            [queueLock unlockWithCondition:QUEUE_IS_KNOWN];
        }
    }
    while( NSOrderedDescending == [aDate compare:[NSDate date]] );
      

    [queueLock lock];
    aLeaf = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];

    [singlePopLock unlock];
    return [aLeaf contentObject];
}


- popBeforeDate:(NSDate *)endDate;
{
    NSDate		*aDate = endDate;
    DatedQueueLeaf	*aLeaf;
    
    [singlePopLock lock];
    [queueLock lock];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];
    do
    {
        if( [queueLock lockWhenCondition:QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSOrderedAscending == [endDate compare:(NSDate *)[[queueArray objectAtIndex:0] contentDate]] ? endDate :(NSDate *)[[queueArray objectAtIndex:0] contentDate]);
            [queueLock unlockWithCondition:QUEUE_IS_KNOWN];
        }
        else
        {
            if( endDate == aDate )
            {
                [singlePopLock unlock];
                return nil;
            }
        }
    }
    while( NSOrderedDescending == [aDate compare:[NSDate date]] );


    [queueLock lock];
    aLeaf = [[[queueArray objectAtIndex:0] retain] autorelease];
    [queueArray removeObjectAtIndex:0];
    [queueLock unlockWithCondition:([queueArray count]?QUEUE_IS_UNKNOWN:QUEUE_IS_KNOWN)];

    [singlePopLock unlock];
    return [aLeaf contentObject];
}


- (void) push:(id)anObject withDate:(NSDate *)aDate;
{
    DatedQueueLeaf *aLeaf = [[DatedQueueLeaf alloc] initWithObject:anObject andDate:aDate];

    [queueLock lock];
    [queueArray addObject:aLeaf];
    [queueLock unlockWithCondition:(([queueArray objectAtIndex:0]==aLeaf)?QUEUE_IS_UNKNOWN:[queueLock condition])];
    [aLeaf release];
}

- (unsigned int) count;
{
    return [queueArray count];
}
- (BOOL)containsObject:(id)anObject;
{
    return [queueArray containsObject:anObject];
}


@end

