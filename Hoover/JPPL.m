/* JPPL.m created by jolly on Fri 09-May-1997 */

#import "JPPL.h"

@implementation JPPL
{
    NSMutableDictionary	*jpplDictionary;
}


+ (id)pplWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{
    return [[JPPL alloc] initWithPath:path create:create readOnly:readOnly];
}

- (void)dealloc
{
    [jpplDictionary release];
    [super dealloc];
}

- (id)initWithPath:(NSString *)path create:(BOOL)create readOnly:(BOOL)readOnly;
{
    NSPPL	*intermediatePPL;
    
    [super init];
    intermediatePPL = [NSPPL pplWithPath:path create:create readOnly:readOnly];
    jpplDictionary = [[NSMutableDictionary alloc] init];
    [jpplDictionary addEntriesFromDictionary:[intermediatePPL rootDictionary]];
    return self;
}

- (NSMutableDictionary *)rootDictionary;
{
    return jpplDictionary;
}

- (void)detachFromFile;
{
    return;
}
- (void)flush;
{
    return;
}
- (void)pushChangesToDisk;
{
    return;
}
- (void)save;
{
    return;
}
- (void)setCacheHalfLife:(NSTimeInterval)halfLife;
{
    return;
}

@end
