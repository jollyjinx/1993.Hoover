/* SortedArray.m created by jolly on Fri 01-Mar-1996 */

#import "SortedArray.h"

#define COMPARE_FUNCTION 1
#define COMPARE_SELECTOR 2

@implementation SortedArray


// NSObject methods

- (id)init
{
    [super init];
    embeddedArray = [[NSMutableArray alloc] init];
    arrayLock = [[NSRecursiveLock alloc] init];
    comparetype = COMPARE_SELECTOR;
    compareselector = @selector(compare:);
    return self;
}

- (void)dealloc
{
    [embeddedArray release];
    [arrayLock release];
    [super dealloc];
}


// NSArray Simple

- (unsigned)count;
{
    return [embeddedArray count];
}

- (id)objectAtIndex:(unsigned)index;
{
    return [embeddedArray objectAtIndex:index];
}


// NSArray (NSCreationMethods)

+ array
{
    return [[[self alloc] init] autorelease];
}

+ (id)arrayWithContentsOfFile:(NSString *)path;
{
    NSArray 	*unsortedArray = [NSArray arrayWithContentsOfFile:path];
    SortedArray *sortedArray = [self array];
    [sortedArray addObjectsFromArray:unsortedArray];
    return sortedArray;
}

+ (id)arrayWithObject:(id)anObject;
{
    SortedArray *sortedArray = [self array];
    [sortedArray addObject:anObject];
    return sortedArray;
}

+ (id)arrayWithObjects:(id)firstObj, ...;
{
    SortedArray *sortedArray = [self array];
    id 		anObject;
    va_list 	ap;

    va_start(ap, firstObj);
    if(firstObj)
    {
        [sortedArray addObject:firstObj];
        while( anObject = va_arg(ap, id) )
        {
            [sortedArray addObject:anObject];
        }
    }
    va_end(ap);
    return sortedArray;
}

- (id)initWithArray:(NSArray *)array;
{
    [[self init] addObjectsFromArray:array];
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path;
{
    NSArray 	*unsortedArray = [NSArray arrayWithContentsOfFile:(NSString *)path];

    [[self init] addObjectsFromArray:unsortedArray];
    return self;
}

- (id)initWithObjects:(id *)objects count:(unsigned)count;
{
    [self init];
    while(count--)
    {
        [self addObject:objects[count]];
    }
    return self;
}

- (id)initWithObjects:(id)firstObj, ...;
{
    id		anObject;
    va_list 	ap;

    [self init];
    va_start(ap, firstObj);
    while( anObject = va_arg(ap, id) )
    {
        [self addObject:anObject];
    }
    va_end(ap);
    return self;
}


#if !defined(STRICT_OPENSTEP)
+ (id)arrayWithArray:(NSArray *)array;
{
    SortedArray *sortedArray = [SortedArray array];
    [sortedArray addObjectsFromArray:array];
    return sortedArray;
}

+ (id)arrayWithObjects:(id *)objs count:(unsigned)cnt;
{
    SortedArray *sortedArray = [SortedArray array];
    [sortedArray initWithObjects:objs count:cnt];
    return sortedArray;
}

#endif 

// New Methods to SortedArray

+ (SortedArray *)sortedArray
{
    return [[[self alloc] init] autorelease];
}

- (NSMutableArray *)unsortedCopy;
{
    return [[embeddedArray mutableCopy] autorelease];
}


- (void)adjustObjectIdenticalTo:(id)objectToAdjust;
{
    [arrayLock lock];
    [embeddedArray removeObjectIdenticalTo:[objectToAdjust retain]];
    [self addObject:objectToAdjust];
    [objectToAdjust release];
    [arrayLock unlock];
}

// NSMutable Array simple functions;


- (void)addObject:(id)anObject;
{
    int	min = 0;
    int max ;
    int mom;
    [arrayLock lock];
    max = [embeddedArray count]-1;
    if( -1 == max)
    {
        [embeddedArray addObject:anObject];
    }
    else
    {
        mom = max/2;

        if( COMPARE_FUNCTION == comparetype )
        {
            while( 1 )
            {
                switch( comparefunction([embeddedArray objectAtIndex:mom],anObject,comparecontext) )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:min],anObject,comparecontext) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:min];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:min+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:min];break;
                            }
                            [arrayLock unlock];
                            return;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( comparefunction([embeddedArray objectAtIndex:max],anObject,comparecontext) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:max];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:max+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:max];break;
                            }
                            [arrayLock unlock];
                            return;
                        }
                        break;
                    }
                    case NSOrderedSame: {[embeddedArray insertObject:anObject atIndex:mom]; [arrayLock unlock]; return;}
                    default: { NSLog(@"SortedArray: comparefuntion returned wrong value - no Object inserted."); return;}
                }
                mom= (min+max)/2;
            }
        }
        else
        {
            while( 1 )
            {
                switch( (int)([[embeddedArray objectAtIndex:mom] performSelector:compareselector withObject:anObject]) )
                {
                    case NSOrderedDescending:
                    {
                        max = mom-1;
                        if( max<=min )
                        {
                            switch( (int)([[embeddedArray objectAtIndex:min] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:min];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:min+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:min];break;
                            }
                            [arrayLock unlock];
                            return;
                        }
                        break;
                    }
                    case NSOrderedAscending:
                    {
                        min = mom+1;
                        if( min>=max )
                        {
                            switch( (int)([[embeddedArray objectAtIndex:max] performSelector:compareselector
                                                                                        withObject:anObject]) )
                            {
                                case NSOrderedDescending:	[embeddedArray insertObject:anObject atIndex:max];break;
                                case NSOrderedAscending:	[embeddedArray insertObject:anObject atIndex:max+1];break;
                                case NSOrderedSame:		[embeddedArray insertObject:anObject atIndex:max];break;
                            }
                            [arrayLock unlock];
                            return;
                        }
                        break;
                    }
                    case NSOrderedSame: {[embeddedArray insertObject:anObject atIndex:mom]; [arrayLock unlock]; return;}
                    default: { NSLog(@"SortedArray: comparemethod returned wrong value - no Object inserted."); return;}
                }
                mom= (min+max)/2;
            }
        }
    }
    [arrayLock unlock];
}

- (void)insertObject:(id)anObject atIndex:(unsigned)index
{
    [self addObject:anObject];
}

- (void)removeObject:(id)anObject;
{
    [arrayLock lock];
    [embeddedArray removeObject:anObject];
    [arrayLock unlock];
}

- (void)removeObjectIdenticalTo:(id)anObject;
{
    [arrayLock lock];
    [embeddedArray removeObjectIdenticalTo:anObject];
    [arrayLock unlock];
}

- (void)removeLastObject
{
    [arrayLock lock];
    [embeddedArray removeLastObject];
    [arrayLock unlock];
}

- (void)removeObjectAtIndex:(unsigned)index;
{
    [arrayLock lock];
    [embeddedArray removeObjectAtIndex:index];
    [arrayLock unlock];
}

- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject;
{
    [arrayLock lock];
    [embeddedArray removeObjectAtIndex:index];
    [self addObject:anObject];
    [arrayLock unlock];
}
// NSMutableArray (NSMutableArrayCreation)

+ (id)arrayWithCapacity:(unsigned)numItems;
{
    return [[[self alloc] initWithCapacity:numItems] autorelease];
}

- (id)initWithCapacity:(unsigned)numItems;
{
    embeddedArray = [[NSMutableArray alloc] initWithCapacity:numItems];
    arrayLock = [[NSRecursiveLock alloc] init];
    comparetype = COMPARE_SELECTOR;
    compareselector =@selector(compare:);
    return self;
}

// Overridden Methods
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange;
{
    [arrayLock lock];
    [embeddedArray removeObjectsInRange:range];
    [self addObjectsFromArray:[otherArray subarrayWithRange:otherRange]];
    [arrayLock unlock];
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray;
{
    [arrayLock lock];
    [embeddedArray removeObjectsInRange:range];
    [self addObjectsFromArray:otherArray];
    [arrayLock unlock];
}

- (void)sortUsingFunction:(int (*)(id, id, void *))compare context:(void *)context;
{
    comparetype = COMPARE_FUNCTION;
    comparefunction = compare;
    comparecontext = context;
    [arrayLock lock];
    [embeddedArray sortUsingFunction:compare context:context];
    [arrayLock unlock];
}

- (void)sortUsingSelector:(SEL)aSelector;
{
    comparetype = COMPARE_SELECTOR;
    compareselector =aSelector;
    [arrayLock lock];
    [embeddedArray sortUsingSelector:aSelector];
    [arrayLock unlock];
}


@end
