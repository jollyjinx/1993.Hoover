/* EODatabaseFile.m created by jolly on Sat 20-Jan-2001 */

#import "EODatabaseFile.h"

#define ENTITY_NAME		@"GDBMStore"
#define ENTITY_KEYNAME		@"sitename"
#define ENTITY_OBJECTNAME	@"object"

@implementation EODatabaseFile


+ (id)newEODatabaseFile:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{
    return [[[self alloc] initWithPath:path create:create readOnly:readOnly] autorelease];
}


- (id)initWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{    
    [super init];

    [EOModelGroup setDefaultGroup:[EOModelGroup new]];
    [[EOModelGroup defaultGroup] addModelWithFile:path];
    eoEditingContext = [[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]];

    if(! (eoClassDescription  = [[EOClassDescription classDescriptionForEntityName:ENTITY_NAME] retain]) )
    {
        NSLog(@"Coudn't get classDescription for Entity:%@",ENTITY_NAME);
        return nil;
    }
   return self;
}

- (void)dealloc
{
    [eoClassDescription release];
    [eoEditingContext release];
}





- (void)flush;
{
    NSLog(@"EODatabaseFile: Flushing context");
    [eoEditingContext saveChanges];
}

- (void)save;
{
    NSLog(@"EODatabaseFile: Saving context");
    [eoEditingContext saveChanges];
}


// size access methods

- (BOOL)isEmpty;
{
    unsigned int i = [self count];
    NSLog(@"EODatabaseFile count:%d",i);
    return (0==i?YES:NO);
}

- (unsigned int)count;
{
    return [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME qualifier:nil sortOrderings:nil]] count];
}


- (NSEnumerator *)keyEnumerator;
{
    NSArray  *eoArray;

    eoArray = [eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME qualifier:nil sortOrderings:nil]];
    if( [eoArray count] )
    {
        return [[eoArray valueForKey:ENTITY_KEYNAME] objectEnumerator];
    }
    
    return nil;
}



- (NSEnumerator *)objectEnumerator;
{
    NSArray  *eoArray;

    eoArray = [eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME qualifier:nil sortOrderings:nil]];
    if( [eoArray count] )
    {
        NSEnumerator   	*objectEnumerator =[[eoArray valueForKey:ENTITY_OBJECTNAME] objectEnumerator];
        NSMutableArray 	*objectArray = [NSMutableArray array];
        NSData		*anObject;
        
        while( anObject = [objectEnumerator nextObject] )
        {
            [objectArray addObject:[NSArchiver archivedDataWithRootObject:anObject]];
        }
        return [objectArray objectEnumerator];
    }

    return nil;
}



//	objectAccess Methods

- (void)setObject:(id)anObject forKey:(id)aKey;
{
    NSArray  *anArray;
    NSObject *changingObject;


    anArray = [eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME
                                                                                                                  qualifier:[EOQualifier qualifierWithQualifierFormat:@"%@ = %@",ENTITY_KEYNAME, aKey]
                                                                                                              sortOrderings:nil]];
    if( [anArray count] )
    {
        changingObject = [anArray objectAtIndex:0];
        //NSLog(@"EODatabaseFile setObject: ForKey: changing %@\n%@ %@",[aKey description],[[NSUnarchiver unarchiveObjectWithData:[changingObject valueForKey:ENTITY_OBJECTNAME]] description],[anObject description]);
        [changingObject takeValue:[NSArchiver archivedDataWithRootObject:anObject] forKey:ENTITY_OBJECTNAME];
    }
    else
    {
        //NSLog(@"EODatabaseFile setObject: ForKey: creating %@\n%@",[aKey description],[anObject description]);
        changingObject = [[[EOGenericRecord alloc] initWithEditingContext:eoEditingContext classDescription:eoClassDescription globalID:nil] autorelease];
        [changingObject takeValue:aKey forKey:ENTITY_KEYNAME];
        [changingObject takeValue:[NSArchiver archivedDataWithRootObject:anObject] forKey:ENTITY_OBJECTNAME];
        [eoEditingContext insertObject:changingObject];
   }

    return;
}


- (id)objectForKey:(id)aKey;
{
    NSArray *anArray;

    anArray = [eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME
                                                                                                           qualifier:[EOQualifier qualifierWithQualifierFormat:@"%@ = %@",ENTITY_KEYNAME, aKey]
                                                                                                       sortOrderings:nil]];
    if( [anArray count] )
    {
        EOGenericRecord *aRecord = [anArray objectAtIndex:0];

        NSMutableDictionary *aDictionary = [NSUnarchiver unarchiveObjectWithData:[aRecord valueForKey:ENTITY_OBJECTNAME]];
        //NSLog(@"EODatabaseFile objectForKey:%@\n%@",[aRecord description],[aDictionary description]);
        return aDictionary;
    }
    return nil;
}


- (void)removeObjectForKey:(id)aKey;
{
    NSArray *anArray;

    anArray = [eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME
                                                                                                           qualifier:[EOQualifier qualifierWithQualifierFormat:@"%@ = %@",ENTITY_KEYNAME, aKey]
                                                                                                       sortOrderings:nil]];
    if( [anArray count] )
    {
        [eoEditingContext deleteObject:[anArray objectAtIndex:0]];
    }
}


@end
