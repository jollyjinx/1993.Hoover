/* Worker.m created by jolly on Wed 14-May-1997 */
#import <HooverFramework/HooverFramework.h>

#import "Worker.h"
#import "HTTPClient.h"

@implementation Worker

+ (Worker *)worker;
{
    return [[[self alloc] init] autorelease];
}

- (void)retrieveUrl:(NSMutableDictionary *)url;
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NS_DURING
        [[HTTPClient httpClient] retrieveUrl:url];
    NS_HANDLER
        NSLog(@"%@.Exception url:%@",[localException reason],[url description]);
        if( (! [[localException name] isEqualToString:@"HTTPClient"] )
            && (! [[localException name] isEqualToString:NSFileHandleOperationException] ))
            [localException raise];	/* Re-raise the exception. */
        [url setObject:[localException reason] forKey:@"errorreason"];
    NS_ENDHANDLER
    [pool release];

    if( [[url objectForKey:@"status"] isEqual:@"invalid"] )
    {
        NSLog(@"Got failure while retieving url:%@",[url description]);
        return;
    }
/*
    if( [[[url objectForKey:@"httpheader"] objectForKey:@"content-type"] hasPrefix:@"text"] )
    {
        NSMutableArray	*urlArray = [NSMutableArray array];
        HTMLDocument	*htmlDocument = [HTMLDocument documentWithData:[url objectForKey:@"httpdata"]];
        NSEnumerator	*objectEnumerator = [[htmlDocument urlArray] objectEnumerator];
       NSString	*urlString;
       NSDictionary	*dict;
        
//       NSLog(@"Document textRepresentation%@ %@",[[htmlDocument htmlArray] description],[htmlDocument textRepresentation]);
//       NSLog(@"Document textRepresentation%@",[htmlDocument textRepresentation]);
/*
        {
            NSString *htmlDocumentText = [htmlDocument textRepresentation];
            if(nil != htmlDocumentText)
                [url setObject:htmlDocumentText forKey:@"textRepresentation"];
            else
                [url setObject:@" " forKey:@"textRepresentation"];
        }
*/
/*
     //  NSLog(@"SGML context:\n%@",[[htmlDocument htmlArray] description]);

        while( urlString = [objectEnumerator nextObject] )
        {
            NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];

            if( dict = [HTMLScanner getDictionaryFromURL:urlString baseUrl:url] )
            {
                [urlArray addObject:dict];
            }
            [pool release];
        }
        if([urlArray count])
        {
            //NSLog(@"Links contained:\n%@",[urlArray description]);
            [url setObject:urlArray forKey:@"links"];
        }

    }
/**/
        
    if( [[[url objectForKey:@"httpheader"] objectForKey:@"HTTP"] hasPrefix:@"30"] && [[url objectForKey:@"httpheader"] objectForKey:@"location"] )
    {
        NSMutableDictionary *redirectionUrl = nil;
        NSString *redirectionString = [[url objectForKey:@"httpheader"] objectForKey:@"location"];
        
        if( [redirectionString hasPrefix:@"http://"] )
        {
            [url setObject:@"redirected" forKey:@"status"];
            if( redirectionUrl = [HTMLScanner getDictionaryFromURL:redirectionString baseUrl:url] )
            {
               [url setObject:[NSMutableArray arrayWithObjects:redirectionUrl,nil] forKey:@"links"];
            }
        }
        else
        {
            if( [redirectionString hasPrefix:@"//"] )
            {
                [url setObject:@"redirected" forKey:@"status"];
                if( redirectionUrl = [HTMLScanner getDictionaryFromURL:[redirectionString substringFromIndex:1] baseUrl:url] )
                {
                    [url setObject:[NSMutableArray arrayWithObjects:redirectionUrl,nil] forKey:@"links"];
                }
            }
            else
            {
                NSLog(@"Unknown Redirection: %@",redirectionString);
                [url setObject:@"invalid" forKey:@"status"];
            }
        }
    }
    #if DEBUG
    NSLog(@"Retrieved url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
    #endif

}
@end
