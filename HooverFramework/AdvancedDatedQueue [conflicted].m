
#import <HooverFramework/AdvancedDatedQueue.h>

#define	FIRST_IN_QUEUE_IS_UNKNOWN	0
#define FIRST_IN_QUEUE_IS_KNOWN		1

@interface AdvancedDatedQueueLeaf : NSObject
{
    id		contentObject;
    NSDate	*contentDate;
}
- initWithObject:(id)anObject andDate:(NSDate *)aDate;
- (NSComparisonResult)compare:(id)anObject;
- contentObject;
- (void)setDate:(NSDate *)aDate;
- (NSDate *) contentDate;
@end

@implementation AdvancedDatedQueueLeaf
{
    id		contentObject;
    NSDate	*contentDate;
}

- (void)dealloc;
{
    [contentObject release];
    [contentDate release];
    [super dealloc];
    //NSLog(@"AdvancedDatedQueueLeaf: -dealloc");
}

- initWithObject:(id)anObject andDate:(NSDate *)aDate;
{
    [super init];

    NSAssert( contentObject = [anObject retain] , @"AdvancedDatedQueueLeaf: -initWithObject:andDate: got called without Object");
    NSAssert( contentDate = [aDate retain]	, @"AdvancedDatedQueueLeaf: -initWithObject:andDate: got called without Date");
    
    return self;
}


- (void)setDate:(NSDate *)aDate;
{
    [contentDate release];
    NSAssert( contentDate = [aDate retain]	, @"AdvancedDatedQueueLeaf: -setDate: got called without Date");
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




@implementation AdvancedDatedQueue
{
    NSConditionLock	*queueLock;
    NSLock		*singlePopLock;
    SortedArray 	*queueArray;
    NSMutableDictionary	*queueDictionary;
}


- init
{
    [super init];
    
    queueLock = [[NSConditionLock alloc] initWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    singlePopLock = [[NSConditionLock alloc] init];
    queueArray = [[SortedArray alloc] init];
    queueDictionary = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) dealloc
{
    [queueLock release];
    [singlePopLock release];
    [queueArray release];
    [queueDictionary release];
    [super release];
}


- pop;
{
    NSDate *aDate = [NSDate distantFuture];
    
    [singlePopLock lock];

    while(1)
    {
        if( YES == [queueLock lockWhenCondition:FIRST_IN_QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[[[queueArray objectAtIndex:0] contentDate] retain] autorelease];
            [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
        }
        else
        {
            [queueLock lock];
            
            if( 0 == [queueArray count] )
            {
                aDate = [NSDate distantFuture];
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
            }
            else
            {
                AdvancedDatedQueueLeaf	*aLeaf = [queueArray objectAtIndex:0];

                if( NSOrderedDescending == [(NSDate*)[NSDate date] compare:(NSDate*)[aLeaf contentDate]] )
                {
                    [[aLeaf retain] autorelease];

                    [queueArray removeObjectAtIndex:0];
                    [queueDictionary removeObjectForKey:[aLeaf contentObject]];

                    [queueLock unlockWithCondition:([queueArray count]?FIRST_IN_QUEUE_IS_UNKNOWN:FIRST_IN_QUEUE_IS_KNOWN)];
                    [singlePopLock unlock];
                    return [aLeaf contentObject];
                }
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_UNKNOWN];
            }                
        }
    }
}

- (BOOL)containsObject:(id)anObject;
{
    return ([queueDictionary objectForKey:anObject])?YES:NO;
}


- (void)removeObjectIdenticalTo:(id)anObject;
{
    AdvancedDatedQueueLeaf	*aLeaf,*firstLeaf;

    [queueLock lock];
    firstLeaf = [queueArray objectAtIndex:0];
    
    NSAssert( aLeaf = [queueDictionary objectForKey:anObject], @"AdvancedDatedQueue: -removeObjectIdenticalTo: got called with unknown Object" );

    [queueDictionary removeObjectForKey:anObject];
    [queueArray removeObjectIdenticalTo:aLeaf];

    if( 0 == [queueArray count] )
    {
        [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    }
    else
    {
        [queueLock unlockWithCondition:((aLeaf==firstLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:[queueLock condition])];
    }
}


- (void)removeAllObjects;
{
    [queueLock lock];
    [queueDictionary release];
    [queueArray release];
    queueArray = [[SortedArray alloc] init];
    queueDictionary = [[NSMutableDictionary alloc] init];
    [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
}



- (void) push:(id)anObject withDate:(NSDate *)aDate;
{
    AdvancedDatedQueueLeaf *aLeaf;
    
    [queueLock lock];

    if( aLeaf = [queueDictionary objectForKey:anObject] )
    {
        [aLeaf setDate:aDate];
        [queueArray adjustObjectIdenticalTo:aLeaf];
    }
    else
    {
        aLeaf = [[[AdvancedDatedQueueLeaf alloc] initWithObject:anObject andDate:aDate] autorelease];

        [queueArray addObject:aLeaf];
        [queueDictionary setObject:aLeaf forKey:anObject];
    }
    [queueLock unlockWithCondition:(([queueArray objectAtIndex:0]==aLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:[queueLock condition])];
}


- (unsigned int) count;
{
    return [queueArray count];
}


@end

