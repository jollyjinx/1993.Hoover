/* Worker.m created by jolly on Wed 14-May-1997 */
#import <HooverFramework/HooverFramework.h>

#import "Worker.h"
#import "HTTPClient.h"

#define SHOULD_WRITE_TEXTUAL_REPRESENTATION 1

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

 

    if( [[[url objectForKey:@"httpheader"] objectForKey:@"content-type"] hasPrefix:@"text"] )
    {
        HTMLDocument	*htmlDocument = [HTMLDocument documentWithData:[url objectForKey:@"httpdata"]];
        BOOL		index = YES;		// per se'  indexing and following the page is allowed
        BOOL		follow = YES;

        // Follow the Robots meta tag
        {
            NSEnumerator	*objectEnumerator = [[htmlDocument htmlArray] objectEnumerator];
            NSDictionary	*tagDictionary;
            NSMutableArray	*tagArray;
            NSString		*optionText,*optionName;

            while( tagArray = [objectEnumerator nextObject] )
            {
                if( [tagArray isKindOfClass:[NSArray class]] )
                {
                    if( (NSOrderedSame == [@"meta" caseInsensitiveCompare:[tagArray objectAtIndex:0]])
                        && ( tagDictionary = [tagArray objectAtIndex:1] )
                        && ( optionName = [tagDictionary objectForKey:@"name"] )
                        && ( NSOrderedSame == [@"robots" caseInsensitiveCompare: optionName] )
                        && ( optionText = [tagDictionary objectForKey:@"content"] )
                        && ( [optionText cStringLength] >= 4) )
                    {
                        NSRange aRange;

                        aRange = [optionText rangeOfString:@"none" options:NSCaseInsensitiveSearch];
                        if( NSNotFound != aRange.location )
                        {	
                            index = NO;
                            follow = NO;
                            objectEnumerator = nil;
                        }
                        else
                        {
                            aRange = [optionText rangeOfString:@"nofollow" options:NSCaseInsensitiveSearch];
                            if( NSNotFound != aRange.location )
                                follow = NO;
                            aRange = [optionText rangeOfString:@"noindex" options:NSCaseInsensitiveSearch];
                            if( NSNotFound != aRange.location )
                                index = NO;
                        }
                    }
                    else
                    {
                        if( [@"body" isEqualToString:[tagArray objectAtIndex:0]] )
                            objectEnumerator = nil;
                    }
                }
            }
        }


        if( NO==index )
        {
            [url removeObjectForKey:@"httpdata"];
            #if DEBUG
            NSLog(@"Wont index data on %@:%@:%@",[url objectForKey:@"hostname"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
            #endif
        }

#if SHOULD_WRITE_TEXTUAL_REPRESENTATION
        if( YES == index )
        {
            NSString *htmlDocumentText = [htmlDocument textRepresentation];
            if(nil != htmlDocumentText)
                [url setObject:htmlDocumentText forKey:@"textRepresentation"];
            else
                [url setObject:@" " forKey:@"textRepresentation"];
        }
#endif
        if( YES == follow )
        {
            NSMutableArray	*urlArray = [NSMutableArray array];
            NSEnumerator	*objectEnumerator = [[htmlDocument urlArray] objectEnumerator];
            NSString		*urlString;
            NSDictionary	*dict;

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
                #if DEBUG > 1
                NSLog(@"Links contained:\n%@",[urlArray description]);
                #endif
                [url setObject:urlArray forKey:@"links"];
            }
        }
        else
        {
            #if DEBUG
            NSLog(@"Wont follow links on %@:%@:%@",[url objectForKey:@"hostname"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
            #endif
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
                if( [redirectionString hasPrefix:@"/"] )
            	{
                	[url setObject:@"redirected" forKey:@"status"];
                	if( redirectionUrl = [HTMLScanner getDictionaryFromURL:redirectionString baseUrl:url] )
                	{
                            [url setObject:[NSMutableArray arrayWithObjects:redirectionUrl,nil] forKey:@"links"];
                	}
            	}
            	else
            	{
                	[url setObject:@"redirected" forKey:@"status"];
                	if( redirectionUrl = [HTMLScanner getDictionaryFromURL:redirectionString baseUrl:url] )
                	{
                            [url setObject:[NSMutableArray arrayWithObjects:redirectionUrl,nil] forKey:@"links"];
                	}
            	}
            }
        }
    }
    #if DEBUG
    NSLog(@"Retrieved url: %@:%@%@",[url objectForKey:@"host"],[url objectForKey:@"port"],[url objectForKey:@"path"]);
    #endif

}
@end
