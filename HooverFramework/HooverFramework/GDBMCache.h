/* JPPL.h created by jolly on Fri 09-May-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/GDBMFile.h>
#import <HooverFramework/AdvancedDatedQueue.h>

@interface GDBMCache : NSObject
{
    NSTimeInterval		cacheLifeTime;
    GDBMFile			*gdbmFile;

    NSRecursiveLock		*cacheLock;
    NSMutableDictionary		*cacheDictionary;
    AdvancedDatedQueue		*cacheDatedQueue;
}

+ (id)gdbmCacheWithGDBMFile:(GDBMFile *)aGDBMFile;
- (id)initWithGDBMFile:(GDBMFile *)aGDBMFile;

- (void)runBackgroundWriteout;
- (void)setCacheLife:(NSTimeInterval)newCacheLife;
- (unsigned int)cacheCount;

- (BOOL)isEmpty;
- (unsigned int)count;
- (void)flush;
- (void)save;

- (NSEnumerator *)keyEnumerator;
- (NSEnumerator *)objectEnumerator;

//	objectAccess Methods

- (void)setObject:(id)anObject forKey:(id)aKey;
- (id)objectForKey:(id)keyObject;
- (void)removeObjectForKey:(id)keyObject;


@end
