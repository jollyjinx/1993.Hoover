/* Worker.m created by jolly on Wed 14-May-1997 */

#import "Worker.h"
#import "HTMLScanner.h"
#import <arpa/inet.h>
#import <sys/socket.h>

@implementation Worker
{
    Fetcher		*fetcherObject;
    BOOL		agentCacheActive;
    NSString 		*userAgentName;
    NSString 		*userAgentMail;
    NSMutableDictionary	*httpProxyDictionary;
}

- (void) dealloc;
{
    [fetcherObject release];
    [userAgentName release];
    [userAgentMail release];
    [httpProxyDictionary release];
    [super dealloc];
}

- (void)runWithController:(ThreadController *)tc;
{
    NSAutoreleasePool	*pool;

    pool = [[NSAutoreleasePool alloc] init];

    agentCacheActive = NO;
    fetcherObject = [tc rootObject];
    [fetcherObject workerWantsWork:self];
    [[NSRunLoop currentRunLoop] run];

    [pool release];
}

- (oneway void)retrieveUrl:(NSMutableDictionary *)url;
{
    NSAutoreleasePool	*threadPool;
    NSString 		*ipAddress;
    u_long		ipaddress;
    struct		sockaddr_in socketaddr;
    int			httpsocket;
    NSFileHandle	*fileHandle;
    NSMutableString	*requestString;
    NSData 		*httpData;
    NSDate		*beginDate,*endDate;
    NSString		*urlPath;
    NSMutableDictionary *originalUrl;

    threadPool = [[NSAutoreleasePool alloc] init];

   if( ! agentCacheActive )
    {
        userAgentName = [[fetcherObject userAgentName] retain];
        userAgentMail = [[fetcherObject userAgentMail] retain];
        httpProxyDictionary = [[fetcherObject httpProxyDictionary] retain];
        agentCacheActive = YES;
    }

    originalUrl = nil;
    if( urlPath = [url objectForKey:@"Location"])
    {
        NSMutableDictionary *redirectedUrl;
        
        if( redirectedUrl = [HTMLScanner getDictionaryFromURL:urlPath])
        {
            originalUrl = url;
            url = redirectedUrl;

            if( [[originalUrl objectForKey:@"Location"] hasSuffix:@"/"] )
            {
                [url setObject:[NSString stringWithFormat:@"%@/",[url objectForKey:@"path"]] forKey:@"path"]; 
            }
            NSLog(@"Got redirection: %@ -> %@",originalUrl,url);
            urlPath = [url objectForKey:@"path"];
            [originalUrl removeObjectForKey:@"HTTP"];
            [originalUrl removeObjectForKey:@"Location"];
            
        }
        else
        {
            NSLog(@"Got simple redirection: %@",url);
        }
    }
    else
    {
        urlPath = [url objectForKey:@"path"];
    }

    [[url retain] autorelease];
    [[urlPath retain] autorelease];

#if DEBBUG
    NSLog(@"Fetching url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],urlPath);
#endif

    //NSLog(@"Fetching url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],urlPath);

    beginDate = [NSDate date];
    httpData = [[NSString stringWithFormat:@"HTTP/1.0 200 Document follows\nContent-type: text/html\n\n\n\n<a href=\"http://fasel.bla.%c%c%c%c%c.de/bluuber\">\n<a href=\"http://fasel.bla.%c%c%c%c%c.de/bluuber\">\nAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n",
        (abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97,
        (abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97,(abs(rand())%20)+97]
 dataUsingEncoding:NSISOLatin1StringEncoding];
    endDate = [NSDate date];

    [url setObject:[NSDate date] forKey:@"lastaccess"];
    [url setObject:[NSNumber numberWithFloat:(float)([httpData length])/(float)((float)[endDate timeIntervalSinceDate:beginDate]+0.1)]
                                   forKey:@"transferrate"];
    [self parseHTTPResponse:httpData intoURL:url];
    [url setObject:@"fetched" forKey:@"status"];

    NSLog(@"Retrieved url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],urlPath);
    
    [fetcherObject retrievedUrl:url withWorker:self];
    [threadPool release];
}

- (void)parseHTTPResponse:(NSData *)httpData intoURL:(NSMutableDictionary *)url;
{
    NSString 		*httpResponse;
    NSString 		*httpHeaderString;
    NSScanner 		*responseScanner;
    NSArray		*lineArray;
    NSEnumerator	*lineEnumerator;
    NSString		*stringToTest;
    NSScanner		*lineScanner;
    NSString		*httpKey;
    NSString		*httpValue;

    httpResponse = [[[NSString alloc] initWithData:httpData encoding:NSISOLatin1StringEncoding] autorelease];
    httpResponse = [[httpResponse componentsSeparatedByString:@"\r"] componentsJoinedByString:@""];
    responseScanner = [NSScanner scannerWithString:httpResponse];

    
    [responseScanner scanUpToString:@"\n\n" intoString:&httpHeaderString];
    [responseScanner scanString:@"\n\n" intoString:NULL];
    [url setObject:[httpResponse substringFromIndex:[responseScanner scanLocation]] forKey:@"contents"];

    lineArray = [httpHeaderString componentsSeparatedByString:@"\n"]; 
    lineEnumerator = [lineArray objectEnumerator];
    while( stringToTest = [lineEnumerator nextObject] )
    {
        lineScanner = [NSScanner scannerWithString:stringToTest];
        if( [stringToTest hasPrefix:@"HTTP/"] )
        {
            int response;
            [lineScanner setScanLocation:8];//[lineScanner scanString:@" " intoString:NULL];
            if( [lineScanner scanInt:&response] )
                [url setObject:[[NSNumber numberWithInt:response] stringValue] forKey:@"HTTP"];
        }
        else
        {
            [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t ;-_"]];
            if( [lineScanner scanUpToString:@":" intoString:&httpKey] )
            {
                [lineScanner scanString:@":" intoString:NULL];
                [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
                if( [lineScanner scanUpToString:@"\n" intoString:&httpValue] )
                {
                    [url setObject:[httpValue lowercaseString] forKey:[httpKey lowercaseString]];
                }
            }
        }
    }

    if( [[url objectForKey:@"HTTP"] isEqual:@"200"] && [[url objectForKey:@"content-type"] hasPrefix:@"text"])
    {
        [url setObject:[HTMLScanner getURLArrayFromHTML:[url objectForKey:@"contents"]] forKey:@"links"];
    }
    
    if( [[url objectForKey:@"HTTP"] hasPrefix:@"30"] && [url objectForKey:@"location"] )
    {
        NSString *redirectionString = [url objectForKey:@"location"];
        
        if( [redirectionString hasPrefix:@"http://"] )
        {
            [url setObject:redirectionString forKey:@"Location"];
        }
        else
        {
            if( [redirectionString hasPrefix:@"//"] )
            {
                [url setObject:[redirectionString substringFromIndex:1] forKey:@"Location"];
            }
            else
            {
                NSLog(@"Unknown Redirection: %@",redirectionString);
                [url setObject:@"400" forKey:@"HTTP"];
            }
        }
    }
}


@end
