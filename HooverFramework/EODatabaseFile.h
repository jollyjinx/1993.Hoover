/* EODatabaseFile.h created by jolly on Sat 20-Jan-2001 */

#import <Foundation/Foundation.h>
#import <EOAccess/EOAccess.h>

@interface EODatabaseFile : NSObject
{
    EOEditingContext *eoEditingContext;
    EOClassDescription *eoClassDescription;
}

+ (id)newEODatabaseFile:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
- (id)initWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;

- (void)flush;
- (void)save;

// size access methods

- (BOOL)isEmpty;
- (unsigned int)count;
- (NSEnumerator *)keyEnumerator;
- (NSEnumerator *)objectEnumerator;


//	objectAccess Methods

- (void)setObject:(id)anObject forKey:(id)anKey;
- (id)objectForKey:(id)anKey;
- (void)removeObjectForKey:(id)anKey;


@end
