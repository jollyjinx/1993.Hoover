/* JPPL.h created by jolly on Fri 09-May-1997 */

#import <Foundation/Foundation.h>

@interface JPPL : NSObject
{
    NSMutableDictionary	*jpplDictionary;
}

+ (id)pplWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
- (id)initWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;

- (NSMutableDictionary *)rootDictionary;

- (void)detachFromFile;
- (void)flush;
- (void)pushChangesToDisk;
- (void)save;
- (void)setCacheHalfLife:(NSTimeInterval)halfLife;

@end
