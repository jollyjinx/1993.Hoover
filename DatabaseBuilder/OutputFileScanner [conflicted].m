/* OutputFileScanner.m created by jolly on Thu 12-Feb-1998 */

#import "OutputFileScanner.h"
#import <HooverFramework/HooverFramework.h>


@implementation OutputFileScanner

- (void)dealloc;
{
    [internalDatabase release];
}


- (id)initWithContentsOfDatabase:(NSString *)aPath;
{
    NSEnumerator	*keyEnumerator;
    id				aKey;
    GDBMFile		*gdbmFile;
	
    internalDatabase = [[NSMutableDictionary alloc] init];

    
    if( (!aPath) || (!(gdbmFile = [GDBMFile gdbmFileWithPath:aPath create:NO readOnly:YES])) )
    {
        NSLog(@"Can't read database at path:%@",aPath);
        return self;
    }
	
    keyEnumerator = [gdbmFile keyEnumerator];
    while( aKey = [keyEnumerator nextObject] )
    {
        id	siteName;
        id	siteDictionary;
		
        siteName = aKey;//[NSUnarchiver unarchiveObjectWithData:aKey];
        siteDictionary = [NSUnarchiver unarchiveObjectWithData:[gdbmFile objectForKey:aKey]];

        NSLog(@"Loading site:%@",siteName);
        //NSLog(@"Contents:%@",[siteDictionary description]);
        [internalDatabase setObject:siteDictionary forKey:siteName];
    }

    return self;
}

- (void)readFiles:(NSArray *)fileNameArray;
{
    NSEnumerator	*fileEnumerator;
    NSString   		*fileName;

    fileEnumerator = [fileNameArray objectEnumerator];
    while( fileName = [fileEnumerator nextObject] )
    {
        NSData				*fileData = [NSData dataWithContentsOfMappedFile:fileName];

       	if( fileData )
        {
            NSAutoreleasePool	*outerPool = [[NSAutoreleasePool alloc] init];
            NSString			*fileAsString;
            NSScanner			*fileScanner;
            
            NSLog(@"Reading file %@:",fileName);
            //fileAsString = [NSString stringWithData:fileData encoding:NSISOLatin1StringEncoding];
            fileAsString = [NSString stringWithData:fileData encoding:[NSString defaultCStringEncoding]];
            fileScanner = [NSScanner scannerWithString:fileAsString];
			
            while( ! [fileScanner isAtEnd] )
            {
                NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
                NSString			*urlName;

                [fileScanner scanUpToString:@"Hoover-Url:" intoString:NULL];
                if( [fileScanner scanString:@"Hoover-Url:" intoString:NULL] )
                {
                    if( [fileScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&urlName] )
                    {
                        NSMutableDictionary	*baseUrl = [HTMLScanner getDictionaryFromURL:[@"http://" stringByAppendingString:urlName] baseUrl:nil];

                        NSLog(@"reading url:%@",urlName);
                        [fileScanner scanUpToString:@"Hoover-Httpdata:\n" intoString:NULL];
                        if( [fileScanner scanString:@"Hoover-Httpdata:\n" intoString:NULL] && baseUrl )
                        {
                            NSString *documentString;
                            
                            if( [fileScanner scanUpToString:@"Hoover-Url:" intoString:&documentString] )
                            {
                                //HTMLDocument *htmlDocument = [HTMLDocument documentWithData:[documentString dataUsingEncoding:NSISOLatin1StringEncoding]];
                                HTMLDocument *htmlDocument = [HTMLDocument documentWithData:[documentString dataUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSEnumerator *urlEnumerator;
                                NSString	 *urlString;
                                
                                urlEnumerator = [[htmlDocument urlArray] objectEnumerator];
                                while( urlString = [urlEnumerator nextObject] )
                                {
                                    NSMutableDictionary *newUrl;
									
                                    if( newUrl = [HTMLScanner getDictionaryFromURL:urlString baseUrl:baseUrl] )
	                                    [self _addUrlToSearchlist:newUrl];
                                }
                                
                            }
                            else
                            {
                                NSLog(@"Url did not contain anything %@",urlName);
                            }
                        }
                    }
					else
                    {
                        NSLog(@"Did not get urlname at : %d",[fileScanner scanLocation]);
                    }
                }
                [innerPool release];
            }
            [outerPool release];
        }
    }
    
}

- (void)writeDatabase:(NSString *)aPath;
{
    GDBMFile		*gdbmFile;
    NSEnumerator	*keyEnumerator;
   	id				aKey;
    
	NSLog(@"Writing database now.");
	if( ! (gdbmFile = [[GDBMFile alloc] initWithPath:aPath create:YES readOnly:NO]) )
    {
        NSLog(@"Can't write database at path:%@",aPath);
        return;
    }

    keyEnumerator = [internalDatabase keyEnumerator];
    while( aKey = [keyEnumerator nextObject] )
    {
        [gdbmFile setObject:[NSArchiver archivedDataWithRootObject:[internalDatabase objectForKey:aKey]]
                     forKey:aKey];
    }
    [gdbmFile flush];
	NSLog(@"Writing flush done.");
    [gdbmFile release];
	NSLog(@"Writing database done.");

}



- (void)_addUrlToSearchlist:(NSMutableDictionary *)newUrl
{
    NSMutableDictionary	*persistentSite;
    NSString			*siteName;

    siteName = [NSString stringWithFormat:@"%@:%@",[newUrl objectForKey:@"host"],[newUrl objectForKey:@"port"]];

    if( persistentSite = [internalDatabase objectForKey:siteName] )
    {
        if( [[persistentSite objectForKey:@"unknownpaths"] objectForKey:[newUrl objectForKey:@"path"]] )
        {
            [newUrl removeObjectForKey:@"host"];
            [newUrl removeObjectForKey:@"port"];
            [newUrl removeObjectForKey:@"method"];
            [newUrl removeObjectForKey:@"subpage"];
            [[persistentSite objectForKey:@"unknownpaths"] setObject:newUrl forKey:[newUrl objectForKey:@"path"]];
        }
    }
    else
    {																												// in case the site is unknown create
        persistentSite = [NSMutableDictionary dictionary];															// persistent and sortedArray entries
        [persistentSite setObject:siteName forKey:@"sitename"];
        [persistentSite setObject:[newUrl objectForKey:@"host"] forKey:@"host"];
        [persistentSite setObject:[newUrl objectForKey:@"port"] forKey:@"port"];
        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"unknownpaths"];
        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"knownpaths"];
        [[persistentSite objectForKey:@"unknownpaths"] setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[newUrl objectForKey:@"path"],@"path",nil]
                                                          forKey:[newUrl objectForKey:@"path"]];
        [internalDatabase setObject:persistentSite forKey:siteName];
    }
}



@end
