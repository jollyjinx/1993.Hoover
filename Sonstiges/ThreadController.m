/* ThreadController.m created by jolly on Mon 10-Mar-1997 */

#import "ThreadController.h"

@implementation ThreadController


- (void)dealloc;
{
    [connectionName release];
    [rootConnection release];
    [super dealloc];
}

- initWithRootObject:(id)root;
{
    [super init];
    connectionName = [[NSString stringWithFormat:@"%x",self] retain];
    rootConnection = [[NSConnection alloc] init] ;
    [rootConnection registerName:connectionName];
    [rootConnection setRootObject:root];
    [rootConnection setIndependentConversationQueueing:YES];
    [[[NSThread currentThread] threadDictionary] setObject:root forKey:connectionName];
    return self;
}

- rootObject;
{
    NSMutableDictionary *dict;
    
    dict = [[NSThread currentThread] threadDictionary];
    if( nil == [dict objectForKey:connectionName] )
    {
        id proxy;
        
        while( nil == ( proxy = [NSConnection rootProxyForConnectionWithRegisteredName:connectionName host:nil] ) )
        {
            NSLog(@"Can't create proxy for local object - waiting");
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.5]];
        }
        [dict setObject:proxy forKey:connectionName];
    }
    return [dict objectForKey:connectionName];
}
@end
