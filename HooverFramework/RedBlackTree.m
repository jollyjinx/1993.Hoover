/* RedBlackTree.m created by jolly on Sat 17-Mar-2001 */

#import "RedBlackTree.h"


@interface RedBlackTreeEnumerator:NSEnumerator
{
    rb_tree		*rbtree;
    rb_traverser	traverser;
}
- initWithRedBlackTree:(rb_tree *)arbtree;

@end

@implementation RedBlackTreeEnumerator

- initWithRedBlackTree:(rb_tree *)arbtree;
{
    [super init];
    rbtree = arbtree;
    traverser.init = 0;
    return self;
}

- (id)nextObject;
{
    return (id)rb_traverse(rbtree,&traverser);
}
@end

static  int compareviamethod(id objectA,id objectB,SEL aselector)
{
    //NSLog(@"comparing");
    //NSLog(@"%@ %@",objectA,objectB);
    return (int)[objectA performSelector:aselector withObject:objectB];
}

static void releaseobjectmethod(id objectA)
{
    [objectA release];
}

@implementation RedBlackTree

+ redBlackTree
{
    return [[[self alloc] init] autorelease];
}

- init
{
    return [self initWithCompareSelector:@selector(compare:)];
}

- initWithCompareFunction:(int (*)(id, id, void *))acomparefunction context:(void *)acontext;
{
    [super init];

    rbTreeLock 		= [[NSLock alloc] init];
    comparefunction	= acomparefunction;
    comparecontext	= acontext;

    rbtree = rb_create(acomparefunction,acontext);
    
    return self;
}

- initWithCompareSelector:(SEL)aselector;
{
    return [self initWithCompareFunction:compareviamethod context:(void *)aselector];
}


- (void)dealloc
{
    [rbTreeLock release];
    rb_destroy(rbtree,releaseobjectmethod);

    [super dealloc];
}

- (void)addObject:(id)anObject;
{
    [rbTreeLock lock];
    if( NULL == rb_insert(rbtree,anObject) )
    {
        [anObject retain];
    }
    [rbTreeLock unlock];
}
- (void)removeObject:(id)anObject;
{
    [rbTreeLock lock];
    if( rb_delete(rbtree,anObject) )
    {
        [anObject release];
    }
    [rbTreeLock unlock];
}

- (BOOL)containsObject:(id)anObject;
{
    BOOL	containsobject;
    [rbTreeLock lock];
    containsobject=rb_find(rbtree,anObject)?YES:NO;
    [rbTreeLock unlock];
    return containsobject;
}

- (id)firstObject;
{
    id	firstObject;
    rb_traverser	traverser;
  
    [rbTreeLock lock];
    traverser.init = 0;
    firstObject =  (id)rb_traverse(rbtree,&traverser);
    [rbTreeLock unlock];
    return firstObject;
}

- (id)removeFirstObject;
{
    id	firstObject;
    rb_traverser	traverser;
  
    [rbTreeLock lock];
    traverser.init = 0;
    if( firstObject = rb_traverse(rbtree,&traverser) )
    {
        rb_delete(rbtree,(void*)firstObject);
    }
    [rbTreeLock unlock];
    return [firstObject autorelease];
   
}




- (unsigned int)count;
{
    unsigned int count;
    [rbTreeLock lock];
    count=rb_count(rbtree);
    [rbTreeLock unlock];
    return count;
}

- (NSEnumerator *)objectEnumerator;
{
    return [[[RedBlackTreeEnumerator alloc] initWithRedBlackTree:rbtree] autorelease];
}

@end
