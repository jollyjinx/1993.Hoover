/* RedBlackTree.h created by jolly on Sat 17-Mar-2001 */

#import <Foundation/Foundation.h>
#import <rb.h>

@interface RedBlackTree : NSObject
{
    rb_tree	*rbtree;
    NSLock	*rbTreeLock;
    int		(*comparefunction)(id, id, void *);
    void	*comparecontext;
}
+ redBlackTree;

- initWithCompareFunction:(int (*)(id, id, void *))acomparefunction context:(void *)acontext;
- initWithCompareSelector:(SEL)aselector;

- (void)addObject:(id)anObject;
- (void)removeObject:(id)anObject;
- (BOOL)containsObject:(id)anObject;

- (id)firstObject;
- (id)removeFirstObject;

- (unsigned int)count;
- (NSEnumerator *)objectEnumerator;
@end
