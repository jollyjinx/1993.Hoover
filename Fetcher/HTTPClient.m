/* HTTPClient.m created by jolly on Thu 18-Dec-1997 */

#import "HTTPClient.h"
#import <HooverFramework/Categories.h>
#import <HooverFramework/HTMLScanner.h>

#import <arpa/inet.h>
#import <sys/socket.h>
#import "nametoaddress.h"

#define	CHAR_CR	0x0d
#define CHAR_LF 0x0a


/* HTTPClient changes	url:	transfertime
				status	(invalid / fetched)
				httpheader
				httpdata
*/

@implementation HTTPClient

static	NSMutableDictionary	*httpClientDictionary;
static	NSMutableDictionary	*httpProxyDictionary;
static	NSLock			*nameserverLookupLock;

+ (void) initialize;
{
    httpClientDictionary = [[NSMutableDictionary dictionaryWithContentsOfFile:@"HTTPClient.configuration"] retain];
    if( httpProxyDictionary = [httpClientDictionary objectForKey:@"httpproxy"] )
    {
        httpProxyDictionary = [[httpClientDictionary objectForKey:@"httpproxy"] mutableCopy];
        if( ! [httpProxyDictionary objectForKey:@"ipaddress"] )
        {
            NSString *ipAddress;
            
            if( !(ipAddress = [[NSHost hostWithName:[httpProxyDictionary objectForKey:@"host"]] address]) )
            {
                NSLog(@"HTTPClient will raise exception: NoIPAddressForProxy");
                [NSException raise:@"HTTPClient" format:@"NoIPAddressForProxy"] ;
            }
            [httpProxyDictionary setObject:ipAddress forKey:@"ipaddress"];
        }
    }
    #if DEBUG
    NSLog(@"HTTPClient.configuration looks like:\n%@",[httpClientDictionary description]);
    #endif
    nameserverLookupLock = [[NSLock alloc] init];
}



+ (HTTPClient *)httpClient;
{
    return [[[self alloc] init] autorelease];
}

- (NSFileHandle *)createConnectionToHost:(NSMutableDictionary *)hostDictionary;
{
    NSString 		*ipAddress;
    char 		*ipaddressstring;
    u_long		ipaddress;
    struct		sockaddr_in socketaddr;
    int			httpsocket;
    int			socketreuse =1;

    
    if( ! (ipAddress = [hostDictionary objectForKey:@"ipaddress"]) )
    {
/**/
        [nameserverLookupLock lock];
        if( 0 == (ipaddressstring = nametoaddress([[NSString stringWithFormat:@"%@.",[hostDictionary objectForKey:@"host"]] cString])) )
        {
            [nameserverLookupLock unlock];
            if( !(ipAddress = [hostDictionary objectForKey:@"host"]) )
            {
                [NSException raise:@"HTTPClient" format:@"UnresolvedHostname"] ;
            }
        }
        else
        {
            [nameserverLookupLock unlock];
            ipAddress = [NSString stringWithCString:ipaddressstring];
        }

/**/
/*
        [nameserverLookupLock lock];
		
	//	NSLog(@"hostWithName: %@",[NSHost hostWithName:[NSString stringWithFormat:@"%@.",[hostDictionary objectForKey:@"host"]]]);
	//	NSLog(@"hostWithAddress: %@ %@",[NSHost hostWithAddress:[hostDictionary objectForKey:@"host"]],[hostDictionary objectForKey:@"host"]);
		
        if( (!(ipAddress = [[NSHost hostWithName:[NSString stringWithFormat:@"%@.",[hostDictionary objectForKey:@"host"]]] address]))
            && (!(ipAddress = [[NSHost hostWithAddress:[NSString stringWithFormat:@"%@",[hostDictionary objectForKey:@"host"]]] address]))
            )
        {
           [nameserverLookupLock unlock];
           [NSException raise:@"HTTPClient" format:@"UnresolvedHostname"] ;
        }
        [nameserverLookupLock unlock];

/**/
        [hostDictionary setObject:ipAddress forKey:@"ipaddress"];
    }

    if( -1 == (ipaddress = (u_long)inet_addr([ipAddress cString])) )
    {
        [NSException raise:@"HTTPClient" format:@"InvalidIPAddress"] ;
    }

    
    socketaddr.sin_port = htons([[hostDictionary objectForKey:@"port"] intValue]);
    socketaddr.sin_family = AF_INET;
    socketaddr.sin_addr.s_addr  = ipaddress;

    if( -1 == (httpsocket = socket(PF_INET,SOCK_STREAM,0)) )					// may be IPPROTO_TCP
    {
        [NSException raise:@"HTTPClient" format:@"UnableToCreateSocket"] ;
    }
    
    if( -1 == setsockopt(httpsocket, SOL_SOCKET, SO_KEEPALIVE, (char *)&socketreuse, sizeof(socketreuse)) )
    {
        close(httpsocket);
        [NSException raise:@"HTTPClient" format:@"UnableToSetKeepalive"] ;
    }

    if( -1 == (connect(httpsocket,(struct sockaddr *)&socketaddr,sizeof(socketaddr))) )
    {
        close(httpsocket);
        [NSException raise:@"HTTPClient" format:@"UnableToConnectSocket"];
    }

    return [NSFileHandle fileHandleWithFileDescriptor:httpsocket closeOnDealloc:YES];
}



- (void)retrieveUrl:(NSMutableDictionary *)url;
{
    NSFileHandle	*conncectionFileHandle;
    NSMutableString	*requestString;
    NSData 		*httpData;
    NSData		*httpHeader;
    NSData		*httpContents;
    NSDate		*beginDate,*endDate;

    [url setObject:@"invalid" forKey:@"status"];
    NSLog(@"HTTPClient:%@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
    
    conncectionFileHandle = [self createConnectionToHost:httpProxyDictionary?httpProxyDictionary:url];

    if( !httpProxyDictionary )
    {
        requestString = [NSMutableString stringWithFormat:@"GET %@ HTTP/1.0\r\n",[url objectForKey:@"path"]];
		[requestString appendFormat:@"Host: %@\r\n",[url objectForKey:@"host"]];
    }
    else
    {
        requestString = [NSMutableString stringWithFormat:@"GET http://%@:%@%@ HTTP/1.0\r\n",
            [url objectForKey:@"host"], [url objectForKey:@"port"],[url objectForKey:@"path"] ];
    }
    [requestString appendFormat:@"User-Agent: %@\r\n",[httpClientDictionary objectForKey:@"useragentname"]];
    [requestString appendFormat:@"From: %@\r\n\r\n",[httpClientDictionary objectForKey:@"useragentmail"]];

    [conncectionFileHandle writeData:[requestString dataUsingEncoding:NSISOLatin1StringEncoding]];
    beginDate = [NSDate date];
    httpData = [conncectionFileHandle readDataToEndOfFile];
    endDate = [NSDate date];
    if( ![httpData length] )
        [NSException raise:@"HTTPClient" format:@"NoDataReadFromServer"];

    [url setObject:[NSNumber numberWithDouble:(double)[endDate timeIntervalSinceDate:beginDate]]
            forKey:@"transfertime"];
    [url setObject:[NSDate date] forKey:@"transferdate"];
    [url setObject:@"fetched" forKey:@"status"];

    NSLog(@"HTTPClient - transfer complete");

    {
        char *beginofdata = (char *)[httpData bytes];
        char *endofdata = beginofdata + [httpData length];
        while( beginofdata < endofdata )
        {
            if( CHAR_LF == *beginofdata++ && (CHAR_LF == *beginofdata || CHAR_CR == *beginofdata ) )
            {
                NSRange	headerrange,contentrange;

                beginofdata++;
                headerrange.location	= 0;
                headerrange.length	= beginofdata - (char *)[httpData bytes];
                contentrange.location	= headerrange.length;
                contentrange.length	= [httpData length] - headerrange.length;

                httpHeader	= [httpData subdataWithRange:headerrange];
                httpContents	= [httpData subdataWithRange:contentrange];

                [url setObject:[self parseHTTPResponse:httpHeader] forKey:@"httpheader"];
                if( [[[url objectForKey:@"httpheader"] objectForKey:@"HTTP"] hasPrefix:@"200"] )
                    [url setObject:httpContents forKey:@"httpdata"];
                beginofdata = endofdata;
            }	
        }
    }
}



- (NSMutableDictionary *)parseHTTPResponse:(NSData *)httpHeader;
{
    NSMutableDictionary	*headerDictionary = [NSMutableDictionary dictionary];
    NSString 			*httpHeaderString;
    NSArray				*lineArray;
    NSEnumerator		*lineEnumerator;
    NSString			*stringToTest;

    //httpHeaderString = [NSString stringWithData:httpHeader encoding:NSISOLatin1StringEncoding];
    httpHeaderString = [NSString stringWithData:httpHeader encoding:[NSString defaultCStringEncoding]];
    httpHeaderString = [[httpHeaderString componentsSeparatedByString:@"\r"] componentsJoinedByString:@""];

    lineArray = [httpHeaderString componentsSeparatedByString:@"\n"]; 
    lineEnumerator = [lineArray objectEnumerator];

    while( stringToTest = [lineEnumerator nextObject] )
    {
        NSScanner	*lineScanner = [NSScanner scannerWithString:stringToTest];

        if( [stringToTest hasPrefix:@"HTTP/"] )
        {
            int response;
            [lineScanner setScanLocation:8];//[lineScanner scanString:@" " intoString:NULL];
            if( [lineScanner scanInt:&response] )
                [headerDictionary setObject:[[NSNumber numberWithInt:response] stringValue] forKey:@"HTTP"];
        }
        else
        {
            NSString	*httpKey;
            NSString	*httpValue;

            [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t ;-_"]];
            if( [lineScanner scanUpToString:@":" intoString:&httpKey] )
            {
                [lineScanner scanString:@":" intoString:NULL];
                [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
                if( [lineScanner scanUpToString:@"\n" intoString:&httpValue] )
                {
                    [headerDictionary setObject:httpValue forKey:[httpKey lowercaseString]];
                }
            }
        }
    }

    return headerDictionary;
}

@end
