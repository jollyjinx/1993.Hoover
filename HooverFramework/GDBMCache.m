/* JPPL.m created by jolly on Fri 09-May-1997 */

#import "GDBMCache.h"

@implementation GDBMCache

- (void)dealloc
{
    [gdbmFile release];
    [cacheLock release];
    [cacheDictionary release];
    [cacheDatedQueue release];
    
    [super dealloc];
}

+ (id)gdbmCacheWithGDBMFile:(GDBMFile *)aGDBMFile;
{
    return [[[self alloc] initWithGDBMFile:aGDBMFile] autorelease];
}

- (id)initWithGDBMFile:(GDBMFile *)aGDBMFile;
{    
    [super init];

    cacheLifeTime= 3600;												// default 20 Minutes

    gdbmFile 	= [aGDBMFile retain];
    cacheLock 	= [[NSRecursiveLock alloc] init];
    cacheDictionary = [[NSMutableDictionary alloc] init];
    cacheDatedQueue = [[AdvancedDatedQueue alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(runBackgroundWriteout)
                             toTarget:self
                           withObject:nil];
    return self;
}

- (void)runBackgroundWriteout
{
    #if DEBUG
        NSLog(@"GDBMCache: starting background writeout");
    #endif

    while(1)
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        id			aKey,anObject;

        aKey = [cacheDatedQueue pop];
        [cacheLock lock];

        if( YES == [cacheDatedQueue containsObject:aKey] )
        {
            NSLog(@"GDBMCache: -runBackgroundWriteout RaceCondition happend.%@",[aKey description]);
        }
        else
        {
            NSAssert1( anObject = [cacheDictionary objectForKey:aKey], @"no Object for key:%@",[aKey description]);

            if( 1 == [anObject retainCount] )		// only if we are the only one that have the object we can write it to disk
            {
                #if DEBUG
                    NSLog(@"GDBMCache: writing to disk:%@ %@  (object retainCount %d)",[aKey description],[anObject description],[anObject retainCount]);
                #endif
                [gdbmFile setObject:anObject forKey:aKey];
                [cacheDictionary removeObjectForKey:aKey];
            }
            else
            {
                NSLog(@"GDBMCache: won't write object %@ to disk - (object retainCount %d)",[aKey description],[anObject retainCount]);
                [cacheDatedQueue push:aKey withDate:[NSDate dateWithTimeIntervalSinceNow:cacheLifeTime]];
            }
        }
        [cacheLock unlock];
        [pool release];
    }
}


- (void)setCacheLife:(NSTimeInterval)newCacheLife;
{
    [cacheLock lock];
    cacheLifeTime = newCacheLife;
    [cacheLock unlock];
}

- (unsigned int)cacheCount;
{
    return [cacheDatedQueue count];
}

- (BOOL)isEmpty;
{
    if( [cacheDictionary count] )
        return YES;
    return [gdbmFile isEmpty];
}
- (unsigned int)count;
{
    [self flush];
    return [gdbmFile count];
}


- (void)flush;
{
    NSEnumerator	*keyEnumerator;
    id			aKey;

    [cacheLock lock];
    keyEnumerator = [cacheDictionary keyEnumerator];
    while( aKey = [keyEnumerator nextObject] )
    {
        [gdbmFile setObject:[cacheDictionary objectForKey:aKey] forKey:aKey];
    }
    [cacheDictionary release];
    cacheDictionary = [[NSMutableDictionary alloc] init];
    [cacheDatedQueue removeAllObjects];
    [gdbmFile flush];
    [cacheLock unlock];
}

- (void)save;
{
    [cacheLock lock];
    [self flush];
    [gdbmFile save];
    [cacheLock unlock];
}


- (NSEnumerator *)keyEnumerator;
{
    [self flush];
    return [gdbmFile keyEnumerator];
}

- (NSEnumerator *)objectEnumerator;
{
    [self flush];
    return [gdbmFile objectEnumerator];
}

//	objectAccess Methods

- (void)setObject:(id)anObject forKey:(id)aKey;
{
    [cacheLock lock];
    
    #if DEBUG
        NSLog(@"GDBMCache: -setObject: forKey: %@  %@(object retainCount:%d)",[anObject description],[aKey description],[anObject retainCount]);
    #endif
    [cacheDictionary setObject:anObject forKey:aKey];
    [cacheDatedQueue push:aKey withDate:[NSDate dateWithTimeIntervalSinceNow:cacheLifeTime]];

    [cacheLock unlock];
}


- (id)objectForKey:(id)aKey;
{
    id			anObject;
    
    [cacheLock lock];
    if( anObject = [cacheDictionary objectForKey:aKey] )
    {
        #if DEBUG
            NSLog(@"GDBMCache: -objectForKey: inCache %@ %@ (object retainCount:%d)",[aKey description],[anObject description],[anObject retainCount]);
        #endif
        [cacheDatedQueue push:aKey withDate:[NSDate dateWithTimeIntervalSinceNow:cacheLifeTime]];
        [[anObject retain] autorelease];
        [cacheLock unlock];
        return anObject;
    }
    

    if( ! (anObject = [gdbmFile objectForKey:aKey]) )
    {
        [cacheLock unlock];
        #if DEBUG
        NSLog(@"GDBMCache: -objectForKey: object not known for key %@",[aKey description]);
        #endif
        return nil;
    }
    
    #if DEBUG
        NSLog(@"GDBMCache: -objectForKey: onDisk %@  %@ (object retainCount:%d)",[aKey description],[anObject description],[anObject retainCount]);
    #endif
    [cacheDictionary setObject:anObject forKey:aKey];
    [cacheDatedQueue push:aKey withDate:[NSDate dateWithTimeIntervalSinceNow:cacheLifeTime]];
    [[anObject retain] autorelease];
    [cacheLock unlock];
    
    return anObject;
}


- (void)removeObjectForKey:(id)aKey;
{
    [cacheLock lock];
    [cacheDictionary removeObjectForKey:aKey];
    [cacheDatedQueue removeObjectIdenticalTo:aKey];
    [gdbmFile removeObjectForKey:aKey];
    [cacheLock unlock];
}



@end
