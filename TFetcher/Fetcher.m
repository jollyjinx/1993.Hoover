/* Fetcher.m created by jolly on Fri 07-Mar-1997 */

#import "Fetcher.h"
#import "Worker.h"


@implementation Fetcher
{
    FetcherController	*hooverObject;

    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
    int			availableconnections;

    NSLock		*crashMachineLock;
}


- (void)dealloc
{
    [hooverObject release];
    
    [userAgentName release];
    [userAgentMail release];
    [httpProxyDictionary release];

    [crashMachineLock release];
    [super dealloc];
}



- (Fetcher *)initWithHooverObject:(FetcherController *)dObject availableConnections:(int)ac;
{
    [super init];

    crashMachineLock = [[NSLock alloc] init];
    availableconnections = ac;
    httpProxyDictionary = nil;
    hooverObject = [dObject retain];
    return self;
}


- (oneway void)fetchUrl:(bycopy NSMutableDictionary *)url;
{
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    Worker *worker = [[Worker alloc] init];

    [worker retrieveUrl:url
          userAgentName:userAgentName
          userAgentMail:userAgentMail
    httpProxyDictionary:httpProxyDictionary
           hooverObject:hooverObject
                   lock:crashMachineLock];
        
    [pool release];
}


- (void) setUserAgentName:(bycopy NSString *)uaName;
{
    userAgentName = [uaName retain];
}
- (NSString*)userAgentName;
{
    return userAgentName;
}


- (void) setUserAgentMail:(bycopy NSString *)uaMail;
{
    userAgentMail = [uaMail retain];
}
- (NSString*)userAgentMail;
{
    return userAgentMail;
}


- (void) setHttpProxy:(bycopy NSMutableDictionary *)uaProxy;
{
    httpProxyDictionary = [uaProxy retain];
}
- (NSMutableDictionary *)httpProxyDictionary;
{
    return httpProxyDictionary;
}


- (NSString *)hostname;
{
    return [NSString stringWithFormat:@"%@:%d",[[NSHost currentHost] name],getpid()];
}
- (int)availableConnections;
{
    return availableconnections;
}

- (void) ping;
{
    #if DEBUG
        NSLog(@"pong");
    #endif
    return;
}
@end
