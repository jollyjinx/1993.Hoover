/* JPPL.m created by jolly on Fri 09-May-1997 */

#import <HooverFramework/GDBMFile.h>

@implementation GDBMFile


+ (id)gdbmFileWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{
    return [[[self alloc] initWithPath:path create:create readOnly:readOnly] autorelease];
}


- (id)initWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{    
    [super init];
    
    gdbmLock = [[NSLock alloc] init];
    gdbmfile = gdbm_open((char *) [path cString], 2048, GDBM_FAST|(create?GDBM_WRCREAT:(readOnly?GDBM_READER:GDBM_WRITER)), 0644, 0 );
    return self;
}

- (void)dealloc
{
    gdbm_close(gdbmfile);
    [gdbmLock release];
    [super dealloc];
}





- (void)flush;
{
    [gdbmLock lock];
    gdbm_sync(gdbmfile);
    [gdbmLock unlock];
}

- (void)save;
{
    [gdbmLock lock];
    gdbm_reorganize(gdbmfile);
    gdbm_sync(gdbmfile);
    [gdbmLock unlock];
}


// size access methods

- (BOOL)isEmpty;
{
    datum		key;

    [gdbmLock lock];
    key = gdbm_firstkey(gdbmfile);
    [gdbmLock unlock];

    return (key.dptr)?NO:YES;
}

- (unsigned int)count;
{
    datum		key,nextkey;
    unsigned int	count;

    [gdbmLock lock];
    count = 0;
    key = gdbm_firstkey(gdbmfile);
    while( key.dptr )
    {
        nextkey = gdbm_nextkey(gdbmfile, key);
        free(key.dptr);
        key = nextkey;
        count++;
    }
    [gdbmLock unlock];
    #if DEBUG
        NSLog(@"GDBMFile count now: %d",count);
    #endif
    return count;
}


- (NSEnumerator *)keyEnumerator;
{
    datum		key,nextkey;
    NSMutableArray	*keyArray = [NSMutableArray array];
    
    [gdbmLock lock];
    key = gdbm_firstkey(gdbmfile);

    while( key.dptr )
    {
        id	aKey;

        aKey = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithBytes:key.dptr length:key.dsize]];
        [keyArray addObject:aKey];

        nextkey = gdbm_nextkey(gdbmfile, key);
        free(key.dptr);
        key = nextkey;
    }
    [gdbmLock unlock];
    return [keyArray objectEnumerator];
}



- (NSEnumerator *)objectEnumerator;
{
    datum		key,nextkey;
    NSMutableArray	*objectArray = [NSMutableArray array];

    [gdbmLock lock];
    key = gdbm_firstkey(gdbmfile);

    while( key.dptr )
    {
        datum object;
        
        object = gdbm_fetch(gdbmfile, key);
        if( object.dptr )
        {
            id	anObject;

            anObject = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithBytes:object.dptr length:object.dsize]];
            [objectArray addObject:anObject];
            free(object.dptr);
        }
        nextkey = gdbm_nextkey(gdbmfile, key);
        free(key.dptr);
        key = nextkey;
    }
    [gdbmLock unlock];
    return [objectArray objectEnumerator];
}



//	objectAccess Methods

- (void)setObject:(id)anObject forKey:(id)aKey;
{
    NSData			*keyData,*objectData;
    datum			key,object;

    if( (!anObject) || (!aKey) )
    {
        #if DEBUG
            NSLog(@"GDBMFile: -setObject:%@ withKey:%@",anObject,aKey);
        #endif
        return;
    }
    keyData = [NSArchiver archivedDataWithRootObject:aKey];
    key.dptr = (void *)[keyData bytes];
    key.dsize = [keyData length];
    
    objectData = [NSArchiver archivedDataWithRootObject:anObject];
    object.dptr = (void *)[objectData bytes];
    object.dsize = [objectData length];

    [gdbmLock lock];
    gdbm_store( gdbmfile,key,object, GDBM_REPLACE );
    [gdbmLock unlock];
}


- (id)objectForKey:(id)aKey;
{
    datum	key,object;
    NSData	*keyData;
    id		anObject;

    keyData = [NSArchiver archivedDataWithRootObject:aKey];
    key.dptr = (void *)[keyData bytes];
    key.dsize = [keyData length];

    [gdbmLock lock];
    object = gdbm_fetch(gdbmfile, key);
    [gdbmLock unlock];

    if( ! object.dptr )
        return nil;
    anObject = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithBytes:object.dptr length:object.dsize]];
    free(object.dptr);

    return anObject;
}


- (void)removeObjectForKey:(id)aKey;
{
    datum	key;
    NSData	*keyData;

    keyData = [NSArchiver archivedDataWithRootObject:aKey];
    key.dptr = (void *)[keyData bytes];
    key.dsize = [keyData length];

    [gdbmLock lock];
    gdbm_delete(gdbmfile, key);
    [gdbmLock unlock];
}


@end
