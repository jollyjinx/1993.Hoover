#import <Foundation/Foundation.h>
#import "gdbm.h"

@interface GDBMFile : NSObject
{
    GDBM_FILE	gdbmfile;
    NSLock	*gdbmLock;
}

+ (id)gdbmFileWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
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
