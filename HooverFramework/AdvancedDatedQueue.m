#import "AdvancedDatedQueue.h"

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
    NSComparisonResult result;
    if( NSOrderedSame == ( result = [contentDate compare:(NSDate *)[anObject contentDate]] ) )
    {
        if(self == anObject) return NSOrderedSame;
        return self<anObject?NSOrderedAscending:NSOrderedDescending;
    }
    return result;
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

- init
{
    [super init];
    
    queueLock = [[NSConditionLock alloc] initWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    singlePopLock = [[NSConditionLock alloc] init];
    queueArray = [[RedBlackTree alloc] init];
    queueDictionary = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) dealloc
{
    [queueLock release];
    [singlePopLock release];
    [queueArray release];
    [queueDictionary release];
    [super dealloc];
}


- pop;
{
    NSDate *aDate = [NSDate distantFuture];
    
    [singlePopLock lock];

    while(1)
    {
        if( YES == [queueLock lockWhenCondition:FIRST_IN_QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[[[queueArray firstObject] contentDate] retain] autorelease];
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
                AdvancedDatedQueueLeaf	*aLeaf = [queueArray firstObject];

                if( NSOrderedDescending == [(NSDate*)[NSDate date] compare:(NSDate*)[aLeaf contentDate]] )
                {
                    NSObject *contentObject = [[aLeaf contentObject] retain];

                    [queueArray removeObject:aLeaf];
                    [queueDictionary removeObjectForKey:contentObject];

                    [queueLock unlockWithCondition:([queueArray count]?FIRST_IN_QUEUE_IS_UNKNOWN:FIRST_IN_QUEUE_IS_KNOWN)];
                    [singlePopLock unlock];
                    return [contentObject autorelease];
                }
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_UNKNOWN];
            }                
        }
    }
}

- popBeforeDate:(NSDate *)endDate;
{
    NSDate *aDate=endDate;
    
    [singlePopLock lock];

    while(1)
    {
        if( YES == [queueLock lockWhenCondition:FIRST_IN_QUEUE_IS_UNKNOWN beforeDate:aDate] )
        {
            aDate = (NSDate *)[[[[queueArray firstObject] contentDate] retain] autorelease];
            [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
        }
        else
        {
            NSDate	*nowDate;

            [queueLock lock];
            nowDate = [NSDate date];
            
            if( 0 == [queueArray count] )
            {
                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
                aDate = endDate;
            }
            else
            {
                AdvancedDatedQueueLeaf	*aLeaf = [queueArray firstObject];

                if( NSOrderedDescending == [nowDate compare:(NSDate*)[aLeaf contentDate]] )
                {
                    NSObject *contentObject = [[aLeaf contentObject] retain];

                    [queueArray removeObject:aLeaf];
                    [queueDictionary removeObjectForKey:contentObject];

                    [queueLock unlockWithCondition:([queueArray count]?FIRST_IN_QUEUE_IS_UNKNOWN:FIRST_IN_QUEUE_IS_KNOWN)];
                    [singlePopLock unlock];
                    return [contentObject autorelease];
                }

                [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_UNKNOWN];
            }

            if( NSOrderedDescending == [nowDate compare:endDate] )
            {
                [singlePopLock unlock];
                return nil;
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
    AdvancedDatedQueueLeaf	*aLeaf;

    [queueLock lock];
    
    NSAssert( aLeaf = [queueDictionary objectForKey:anObject], @"AdvancedDatedQueue: -removeObjectIdenticalTo: got called with unknown Object" );

    [queueDictionary removeObjectForKey:anObject];
    [queueArray removeObject:aLeaf];

    if( 0 == [queueArray count] )
    {
        [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
    }
    else
    {
        [queueLock unlockWithCondition:(([queueArray firstObject]==aLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:[queueLock condition])];
    }
}


- (void)removeAllObjects;
{
    [queueLock lock];

    [queueDictionary release];
    [queueArray release];
    
    queueArray		= [[RedBlackTree alloc] init];
    queueDictionary	= [[NSMutableDictionary alloc] init];
    
    [queueLock unlockWithCondition:FIRST_IN_QUEUE_IS_KNOWN];
}



- (void) push:(id)anObject withDate:(NSDate *)aDate;
{
    AdvancedDatedQueueLeaf *aLeaf;
    
    [queueLock lock];

    if( aLeaf = [queueDictionary objectForKey:anObject] )
    {
        [queueArray removeObject:aLeaf];
        [aLeaf setDate:aDate];
        [queueArray addObject:aLeaf];
    }
    else
    {
        aLeaf = [[AdvancedDatedQueueLeaf alloc] initWithObject:anObject andDate:aDate];

        [queueArray addObject:aLeaf];
        [queueDictionary setObject:aLeaf forKey:anObject];
        [aLeaf release];
    }
    [queueLock unlockWithCondition:(([queueArray firstObject]==aLeaf)?FIRST_IN_QUEUE_IS_UNKNOWN:[queueLock condition])];
}


- (unsigned int) count;
{
    return [queueArray count];
}


@end

