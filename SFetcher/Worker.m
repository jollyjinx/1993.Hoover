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

    NS_DURING
    if( !httpProxyDictionary )
    {
        if( ! (ipAddress = [url objectForKey:@"ipaddress"]) )
        {
            if( !(ipAddress = [[NSHost hostWithName:[url objectForKey:@"host"]] address]) )
                [NSException raise:@"FetcherSocket" format:@"Can't resolve hostname"] ;

            [url setObject:ipAddress forKey:@"ipaddress"];
        }

        if( -1 == (ipaddress = (u_long)inet_addr([ipAddress cString])) )
            [NSException raise:@"FetcherSocket" format:@"Can't get ipaddress integer from ipAddress String"] ;

        socketaddr.sin_port = htons([[url objectForKey:@"port"] intValue]);
        socketaddr.sin_family = AF_INET;
        socketaddr.sin_addr.s_addr  = ipaddress;
    }
    else
    {
        if( ! (ipAddress = [httpProxyDictionary objectForKey:@"ipaddress"]) )
        {
            if( !(ipAddress = [[NSHost hostWithName:[httpProxyDictionary objectForKey:@"host"]] address]) )
                [NSException raise:@"FetcherSocket" format:@"Can't resolve hostname for proxy"] ;

            [httpProxyDictionary setObject:ipAddress forKey:@"ipaddress"];
        }

        if( -1 == (ipaddress = (u_long)inet_addr([ipAddress cString])) )
            [NSException raise:@"FetcherSocket" format:@"Can't get ipaddress integer from ipAddress String"] ;

        socketaddr.sin_port = htons([[httpProxyDictionary objectForKey:@"port"] intValue]);
        socketaddr.sin_family = AF_INET;
        socketaddr.sin_addr.s_addr  = ipaddress;
    }

    if( -1 == (httpsocket = socket(PF_INET,SOCK_STREAM,0)) )				// may be IPPROTO_TCP
        [NSException raise:@"FetcherSocket" format:@"Can't create socket."] ;


    if( -1 == (connect(httpsocket,(struct sockaddr *)&socketaddr,sizeof(socketaddr))) )
    {
        perror("ERROR No. ");
        [NSException raise:@"FetcherSocket" format:@"Can't create connection for socket."];

    }

    fileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:httpsocket closeOnDealloc:YES] autorelease];

    if( !httpProxyDictionary )
    {
        requestString = [NSMutableString stringWithFormat:@"GET %@ HTTP/1.0\n",urlPath];
    }
    else
    {
        requestString = [NSMutableString stringWithFormat:@"GET http://%@:%@%@ HTTP/1.0\n",
            [url objectForKey:@"host"],[url objectForKey:@"port"],urlPath];
    }
    [requestString appendFormat:@"User-Agent: %@\n",userAgentName];
    [requestString appendFormat:@"From: %@\n\r\n\r\n",userAgentMail];

    [fileHandle writeData: [requestString dataUsingEncoding:NSISOLatin1StringEncoding]];
    //[fileHandle writeData: [[HTMLScanner encodeISOLatin1:requestString] dataUsingEncoding:NSISOLatin1StringEncoding]];

    beginDate = [NSDate date];
    if( (nil == ( httpData = [fileHandle readDataToEndOfFile])) || (![httpData length]) )
        [NSException raise:@"FetcherSocket" format:@"Did not read any data from server."];
    endDate = [NSDate date];

    [url setObject:[NSDate date] forKey:@"lastaccess"];
    [url setObject:[NSNumber numberWithFloat:(float)([httpData length])/(float)((float)[endDate timeIntervalSinceDate:beginDate]+0.1)]
                                   forKey:@"transferrate"];
    [url setObject:@"400" forKey:@"HTTP"];			// some sites do not adhere the specification
    [self parseHTTPResponse:httpData intoURL:url];
    [url setObject:@"fetched" forKey:@"status"];
    
    NS_HANDLER
    if( [[localException name] isEqualToString:@"FetcherSocket"] )
    {
        NSLog(@"%@.Exception url:%@",[localException reason],[url description]);
        [url setObject:[NSDate date] forKey:@"lastaccess"];
        [url setObject:[NSNumber numberWithInt:1] forKey:@"transferrate"];
        [url setObject:@"invalid" forKey:@"status"];
        [url setObject:@"400" forKey:@"HTTP"];
    }
    else
    if( [[localException name] isEqualToString:@"NSFileHandleOperationException"] )
    {
        NSLog(@"%@. filehandle Exception:%@",[localException reason],[url description]);
        [url setObject:[NSDate date] forKey:@"lastaccess"];
        [url setObject:[NSNumber numberWithInt:1] forKey:@"transferrate"];
        [url setObject:@"invalid" forKey:@"status"];
        [url setObject:@"400" forKey:@"HTTP"];
    }
    else
        [localException raise];	/* Re-raise the exception. */

    NS_ENDHANDLER

    if( nil != originalUrl )
    {
        NSEnumerator *keyEnumerator = [originalUrl keyEnumerator];
        NSString *keyString;
        
        while( keyString = [keyEnumerator nextObject] )
        {
            [url setObject:[originalUrl objectForKey:keyString] forKey:keyString];
        }
    }
#if DEBUG
    NSLog(@"Retrieved url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],urlPath);
#endif
    
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
