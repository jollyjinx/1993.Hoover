/* SortedArray.h created by jolly on Fri 01-Mar-1996 */

#import <Foundation/Foundation.h>

@interface SortedArray : NSMutableArray
{
@private
    NSMutableArray 	*embeddedArray;
    NSRecursiveLock	*arrayLock;
    int			comparetype;
    int 		(*comparefunction)(id, id, void *);
    void 		*comparecontext;
    SEL			compareselector;
}

// Due to the fact that NSArray is a Class Cluster I use the 'embedded object' way of using a subclass
+ (id)sortedArray;
- (NSMutableArray *)unsortedCopy;
- (void)adjustObjectIdenticalTo:(id)objectToAdjust;
@end
