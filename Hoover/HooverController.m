/* HooverController.m created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>

#import "HooverController.h"
#import "FetcherController.h"
#import "RobotScanner.h"


#define	CONDITION_QUEUE_EMPTY		0
#define	CONDITION_QUEUE_NOT_EMPTY	1


static NSComparisonResult compareserver(NSMutableDictionary *server1, NSMutableDictionary *server2, int context)
{
    if( ! [server1 objectForKey:@"nextaccess"] ) return NSOrderedAscending;
    if( ! [server2 objectForKey:@"nextaccess"] ) return NSOrderedDescending;
    return [(NSDate *)[server1 objectForKey:@"nextaccess"] compare:(NSDate *)[server2 objectForKey:@"nextaccess"]];
}


@implementation HooverController : NSObject
{
    JPPL		*propertyList;

    NSConditionLock	*writeToFileLock;
    NSMutableArray	*writeToFileQueue;
    
    NSConditionLock	*receivedUrlsQueueLock;	
    NSMutableArray	*receivedUrlsQueue;
    NSMutableArray	*sendingUrlsQueue;
    FetcherController	*fetcherController;
    
    NSMutableDictionary	*allSitesDictionary;
    SortedArray		*allSitesSortedArray;

    RobotScanner	*generalScanner;

    NSString		*userAgentName;
    NSString		*userAgentMail;
    NSMutableDictionary	*httpProxy;
}

- (void)dealloc
{
    [propertyList release];

    [writeToFileQueue release];
    [writeToFileLock release];
    
    [receivedUrlsQueueLock release];
    [receivedUrlsQueue release];
    [sendingUrlsQueue release];
    [fetcherController release];

    [allSitesDictionary release];
    [allSitesSortedArray release];
    
    [generalScanner release];

    
    [userAgentName release];
    [userAgentMail release];
    [httpProxy release];
    
    [super dealloc];
}


- (HooverController *)initWithConfiguration:(NSDictionary *)configurationDictionary;
{
    NSMutableDictionary *generalConfiguration;
    NSMutableDictionary *persistentSitesDictionary;

    [super init];

    writeToFileLock = [[NSConditionLock alloc] initWithCondition:CONDITION_QUEUE_EMPTY];
    writeToFileQueue = [[NSMutableArray alloc] init];
    [NSThread detachNewThreadSelector:@selector(runTheWriteToFileLoop)
                             toTarget:self
                           withObject:nil];
   
    receivedUrlsQueue = [[NSMutableArray alloc] init];
    sendingUrlsQueue = [[NSMutableArray alloc] init];
    receivedUrlsQueueLock = [[NSConditionLock alloc] initWithCondition:CONDITION_QUEUE_EMPTY];
    
    if( ! (generalConfiguration =[configurationDictionary objectForKey:@"general"]) )
    {
        NSLog(@"No 'general' Dictionary in configuration file.");
        return nil;
    }
    if(! (propertyList = [[JPPL pplWithPath:[generalConfiguration objectForKey:@"databasename"]
                                      create:YES
                                    readOnly:NO] retain]) )
    {
        NSLog(@"Couldn't open or create %@", [generalConfiguration objectForKey:@"databasename"]);
        return nil;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self	
                                             selector:@selector(propertyListBecameInvalid:)
                                                 name:NSPPLDidSaveNotification
                                               object:propertyList];
    //[propertyList setCacheHalfLife:(NSTimeInterval)1000.00];

    allSitesDictionary = [[NSMutableDictionary dictionary] retain];
    allSitesSortedArray = [[SortedArray sortedArray] retain];
    [allSitesSortedArray sortUsingFunction:(int (*)(id, id, void *))&compareserver context:NULL];

    userAgentName = [[generalConfiguration objectForKey:@"useragentname"] retain];
    userAgentMail = [[generalConfiguration objectForKey:@"useragentmail"] retain];
    if( [generalConfiguration objectForKey:@"httpproxy"] )
    {
        httpProxy = [[[generalConfiguration objectForKey:@"httpproxy"] mutableCopy] retain];
    }
    generalScanner = [[RobotScanner alloc] initWithContentsOfGeneralConfiguration:generalConfiguration];

    persistentSitesDictionary = [propertyList rootDictionary];

    if( 0 == [persistentSitesDictionary count])						// first use of program
    {
        NSMutableDictionary	*urls;
        NSEnumerator		*objectEnumerator;

        NSString		*urlString;
        NSMutableDictionary	*urlDictionary;

        if( ! (urls =[configurationDictionary objectForKey:@"urls"]) )
        {
            NSLog(@"No 'urls' Dictionary in configuration file.");
            return nil;
        }
        objectEnumerator = [urls objectEnumerator];
        while( urlString = [objectEnumerator nextObject])
        {
            if( urlDictionary = [HTMLScanner getDictionaryFromURL:urlString] )
            {
                [self addUrlToSearchlist:urlDictionary];
            }
        }
    }
    else
    {
        NSEnumerator	*objectEnumerator = [persistentSitesDictionary keyEnumerator];
        NSString	*siteName;

        NSLog(@"Found %d sites in persistent property list.",[persistentSitesDictionary count]);
        while( siteName = [objectEnumerator nextObject] )
        {
            NSMutableDictionary	*persistentSite = [persistentSitesDictionary objectForKey:siteName];
            NSMutableDictionary	*searchSite = [NSMutableDictionary dictionary];
            NSMutableDictionary	*url;
            NSMutableDictionary	*pathsDictionary;
            NSEnumerator 	*keyEnumerator;
            NSString 		*keyString;
            NSMutableArray	*keysToRemove = [NSMutableArray array];

            //NSLog(@"Loading and testing site: %@",siteName);
            //NSLog(@"Site contents: %@",[persistentSite description]);

            pathsDictionary = [persistentSite objectForKey:@"unknownpaths"];
            keyEnumerator = [pathsDictionary keyEnumerator];
            while( keyString = [keyEnumerator nextObject] )
            {
                if( nil == [[pathsDictionary objectForKey:keyString] objectForKey:@"path"] )
                {
                    NSLog(@"Reading Error with site: %@",persistentSite);
                    [keysToRemove addObject:keyString];
                }
            }
            [pathsDictionary removeObjectsForKeys:keysToRemove];
            
            pathsDictionary = [persistentSite objectForKey:@"knownpaths"];
            keyEnumerator = [pathsDictionary keyEnumerator];
            while( keyString = [keyEnumerator nextObject] )
            {
                if( nil == [[pathsDictionary objectForKey:keyString] objectForKey:@"path"] )
                {
                    NSLog(@"Reading Error with site: %@",persistentSite);
                    [keysToRemove addObject:keyString];
                }
            }
            [pathsDictionary removeObjectsForKeys:keysToRemove];

            
            if( url = [[persistentSite objectForKey:@"knownpaths"] objectForKey:@"/robots.txt"] )
            {
                RobotScanner *robotScanner;

                if( [[url objectForKey:@"HTTP"] hasPrefix:@"200"] )
                {
                    if( robotScanner = [[RobotScanner alloc] initWithUrl:url userAgentName:userAgentName] )
                        [searchSite setObject:robotScanner forKey:@"robotScanner"];
                }
            }


            [searchSite setObject:[persistentSite objectForKey:@"sitename"] forKey:@"sitename"];
            [searchSite setObject:[persistentSite objectForKey:@"host"] forKey:@"host"];
            [searchSite setObject:[persistentSite objectForKey:@"port"] forKey:@"port"];
            [searchSite setObject:[NSDate date] forKey:@"nextaccess"];

            [allSitesSortedArray addObject:searchSite];
            [allSitesDictionary setObject:searchSite forKey:[searchSite objectForKey:@"sitename"]];
        }
    }

    NSLog(@"Configuration file read.");

    fetcherController = [[FetcherController alloc] init];
    [NSThread detachNewThreadSelector:@selector(runWithHooverController:)
                                  toTarget:fetcherController
                                  withObject:self];
    return self;
}


- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl
{
    NSMutableDictionary *persistentSitesDictionary;
    NSMutableDictionary *persistentSite ;
    NSMutableDictionary *searchSite ;
    NSString		*siteName;

    persistentSitesDictionary = [propertyList rootDictionary];
    
    if( ! [generalScanner urlIsWanted:newUrl] )
    {
        //NSLog(@"General Scanner rejects: %@",[newUrl description]);
        return;
    }
    siteName = [NSString stringWithFormat:@"%@:%@",[newUrl objectForKey:@"host"],[newUrl objectForKey:@"port"]];
    
    if( ! (persistentSite = [persistentSitesDictionary objectForKey:siteName] ) )
    {
        persistentSite = [NSMutableDictionary dictionary];
        [persistentSite setObject:siteName forKey:@"sitename"];
        [persistentSite setObject:[newUrl objectForKey:@"host"] forKey:@"host"];
        [persistentSite setObject:[newUrl objectForKey:@"port"] forKey:@"port"];
        searchSite = [persistentSite mutableCopy];

        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"unknownpaths"];
        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"knownpaths"];
        [persistentSitesDictionary setObject:persistentSite forKey:[persistentSite objectForKey:@"sitename"]];

        [searchSite setObject:[NSDate date] forKey:@"nextaccess"];
        [allSitesSortedArray addObject:searchSite];
        [allSitesDictionary setObject:searchSite forKey:[searchSite objectForKey:@"sitename"]];
    }


    [newUrl removeObjectForKey:@"host"];
    [newUrl removeObjectForKey:@"port"];
    [newUrl removeObjectForKey:@"method"];
    [newUrl removeObjectForKey:@"subpage"];

    if(! [[persistentSite objectForKey:@"knownpaths"] objectForKey:[newUrl objectForKey:@"path"]] )
    {
        //NSLog(@"Adding: %@",[newUrl description]);
        [[persistentSite objectForKey:@"unknownpaths"] setObject:newUrl forKey:[newUrl objectForKey:@"path"]];
        //NSLog(@"Added: %@",[[persistentSite objectForKey:@"unknownpaths"] objectForKey:[newUrl objectForKey:@"path"]]);
    }
}

- (void)runTheLoop;
{
    NSAutoreleasePool 	*outerPool;

    while(1)
    {
        outerPool = [[NSAutoreleasePool alloc] init];

        while( [sendingUrlsQueue count] && [self workOnSendingUrlsQueue] );			// First feed the fetcherController

        if( CONDITION_QUEUE_NOT_EMPTY == [receivedUrlsQueueLock condition] )
        {
            [self workOnReceivedUrlsQueue];
        }

        [self putWorkInSendingUrlsQueue];
        [outerPool release];
    }
}

- (void)putWorkInSendingUrlsQueue;
{
    NSMutableDictionary	*knownDictionary;
    NSMutableDictionary	*unknownDictionary;
    NSMutableDictionary *searchSite;
    NSMutableDictionary *persistentSitesDictionary;
    NSMutableDictionary *persistentSite;
    NSMutableDictionary	*url;
    RobotScanner	*robotScanner;


    persistentSitesDictionary = [propertyList rootDictionary];

    if( [allSitesSortedArray count] )										// has work to do
    {
        searchSite = [allSitesSortedArray objectAtIndex:0];
        persistentSite = [persistentSitesDictionary objectForKey:[searchSite objectForKey:@"sitename"]];

        if( NSOrderedDescending == [(NSDate *)[searchSite objectForKey:@"nextaccess"] compare:[NSDate date]] )	// no work - wait
        {													// for reply
            if( CONDITION_QUEUE_EMPTY == [receivedUrlsQueueLock condition] )
            {
                if( ![sendingUrlsQueue count] )
                {
                    #if DEBUG
                        NSLog(@"Waiting for Site %@ (first in line ) has nextaccess at %@",[searchSite objectForKey:@"sitename"],
                                [[searchSite objectForKey:@"nextaccess"] description]);
                    #endif
                    if( YES == [receivedUrlsQueueLock lockWhenCondition:CONDITION_QUEUE_NOT_EMPTY
                                                            beforeDate:[searchSite objectForKey:@"nextaccess"]] )
                        [receivedUrlsQueueLock unlockWithCondition:[receivedUrlsQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
                }
                else
                {
                    #if DEBUG
                         NSLog(@"Waiting one Second for FetcherController to come ready");
                    #endif
                    if( YES == [receivedUrlsQueueLock lockWhenCondition:CONDITION_QUEUE_NOT_EMPTY
                                                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]] )
                        [receivedUrlsQueueLock unlockWithCondition:[receivedUrlsQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];
                }
            }
            return;
       }
        else						
        {	
            url = nil;											// 'hmmm work to do
            unknownDictionary =  [persistentSite objectForKey:@"unknownpaths"];
            knownDictionary = [persistentSite objectForKey:@"knownpaths"];

            if( ! [knownDictionary objectForKey:@"/robots.txt"] )
            {
                url = [NSMutableDictionary dictionary];
                [url setObject:@"/robots.txt" forKey:@"path"];
                [unknownDictionary removeObjectForKey:[url objectForKey:@"path"]];
            }
            else
            {
                if( 0 == [unknownDictionary count] )
                {
                    #if DEBUG
                    NSLog(@"Site %@ has no unknown urls right now.",[searchSite objectForKey:@"sitename"]);
                    #endif
                    [searchSite setObject:[NSDate distantFuture] forKey:@"nextaccess"];
                    [allSitesSortedArray removeObject:searchSite];
                    [allSitesSortedArray addObject:searchSite];
                }
                else
                {
                    url = [[[unknownDictionary objectEnumerator] nextObject] mutableCopy];
                    [unknownDictionary removeObjectForKey:[url objectForKey:@"path"]];

                    if( (robotScanner = [searchSite objectForKey:@"robotScanner"]) && ( [RobotScanner class] == [robotScanner class]) )
                    {
                        if( ! [robotScanner urlIsWanted:url] )
                        {
                            #if DEBUG
                            NSLog(@"Site Scanner rejects: %@",[url description]);
                            #endif
                            [url setObject:@"rejected from siteScanner" forKey:@"status"];
                            [knownDictionary setObject:url forKey:[url objectForKey:@"path"]];
                            url=nil;
                        }
                    }
                }
            }

            if( nil != url )
            {
                NSString	*ipaddress;

                [url setObject:[searchSite objectForKey:@"sitename"] forKey:@"sitename"];
                [url setObject:[searchSite objectForKey:@"host"] forKey:@"host"];
                [url setObject:[searchSite objectForKey:@"port"] forKey:@"port"];
                if( ipaddress = [searchSite objectForKey:@"ipaddress"] ) [url setObject:ipaddress forKey:@"ipaddress"];

                [searchSite setObject:[NSDate distantFuture] forKey:@"nextaccess"];
                [allSitesSortedArray removeObject:searchSite];
                [allSitesSortedArray addObject:searchSite];

                [sendingUrlsQueue addObject:url];
                #if DEBUG
  		 NSLog(@"HooverController stuffing url - (S:%d R:%d) in queues now.",[sendingUrlsQueue count],[receivedUrlsQueue count]);
                #endif
           }
            else
            {
                //NSLog(@"Url == nil");
            }
        }
    }
    else
    {
        NSLog(@"No more work to do. - This should not happen.");
    }
}



- (void)retrievedUrl:(NSMutableDictionary *)url;
{
    [receivedUrlsQueueLock lock];
    [receivedUrlsQueue addObject:url];
    [receivedUrlsQueueLock unlockWithCondition:CONDITION_QUEUE_NOT_EMPTY];

    [writeToFileLock lock];
    [writeToFileQueue addObject:url];
    [writeToFileLock unlockWithCondition:CONDITION_QUEUE_NOT_EMPTY];
}



- (BOOL) workOnSendingUrlsQueue;
{
    NSMutableDictionary *url;

    url = [sendingUrlsQueue objectAtIndex:0];
    if( [fetcherController fetchLocalUrl:url] )
    {
        [sendingUrlsQueue removeObjectAtIndex:0];
        return YES;
    }
    return NO;
}



- (void)workOnReceivedUrlsQueue;
{
    NSMutableDictionary	*url;
    static 		retrievedurlcounter = 0;
    double 		deltatime;
    RobotScanner	*robotScanner;
    NSString		*siteName;
    NSString		*urlPath;
    NSMutableDictionary	*searchSite;
    NSMutableDictionary *persistentSitesDictionary;
    NSMutableDictionary	*persistentSite;
    NSMutableDictionary *persistentUrl;

    [receivedUrlsQueueLock lock];
    if( ! [receivedUrlsQueue count] )
    {
        NSLog(@"HooverController - workOnQueue called without work");
        [receivedUrlsQueueLock unlockWithCondition:CONDITION_QUEUE_EMPTY];
        return;
    }

    url = [[receivedUrlsQueue objectAtIndex:0] retain];
    [receivedUrlsQueue removeObjectAtIndex:0];
    [receivedUrlsQueueLock unlockWithCondition:[receivedUrlsQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];

    #if DEBUG
    NSLog(@"HooverController working on:%@%@ %@",[url objectForKey:@"sitename"],[url objectForKey:@"path"],[url objectForKey:@"status"]);
    #endif

    if( ! (retrievedurlcounter = (retrievedurlcounter+1)%10000) )
    {
        NSLog(@"Saving persistent property list");
        [propertyList save];
        NSLog(@"Saving done.");
    }
    else if( ! (retrievedurlcounter%500) )
    {
        NSLog(@"Flushing persistent property list");
        [propertyList flush];
        NSLog(@"Flush done.");
    }

    
    persistentSitesDictionary = [propertyList rootDictionary];
    siteName = [url objectForKey:@"sitename"];
    persistentUrl = [NSMutableDictionary dictionary];
    persistentSite = [persistentSitesDictionary objectForKey:siteName];
    searchSite = [allSitesDictionary objectForKey:siteName];
    
    if( ! (urlPath = [url objectForKey:@"path"]) )
    {
        NSLog(@"Got URL without path:%@",[url description]);
        [url release];
        return;
    }
    [persistentUrl setObject:[url objectForKey:@"HTTP"] forKey:@"HTTP"];
    [persistentUrl setObject:urlPath forKey:@"path"];

        
    if( [@"/robots.txt" isEqual:urlPath] )
    {
        if(! [[url objectForKey:@"HTTP"] hasPrefix:@"200"] )
        {
            //NSLog(@"/robots.txt not found on:%@",siteName);
        }
        else
        {
            //NSLog(@"/robots.txt found on site:%@",siteName);
            if( robotScanner = [[RobotScanner alloc] initWithUrl:url userAgentName:userAgentName] )
            {
                [persistentUrl setObject:[url objectForKey:@"contents"] forKey:@"contents"];
                [searchSite setObject:robotScanner forKey:@"robotScanner"];
                [robotScanner release];
            }
        }
    }


    if( [[url objectForKey:@"status"] isEqual:@"fetched"] )
    {
        if( [[url objectForKey:@"HTTP"] hasPrefix:@"30"] && [url objectForKey:@"Location"])
        {
            //NSLog(@"Redirection on url:%@",urlPath);
            [persistentUrl setObject:[url objectForKey:@"Location"] forKey:@"Location"];
            [[persistentSite objectForKey:@"unknownpaths"] setObject:persistentUrl forKey:urlPath];
        }
        else
        {
            [[persistentSite objectForKey:@"knownpaths"] setObject:persistentUrl forKey:urlPath];

            if( [[url objectForKey:@"HTTP"] hasPrefix:@"200"] )
            {
                NSMutableArray	*newUrlArray;

                if( newUrlArray = [url objectForKey:@"links"] )
                {
                    NSEnumerator	*objectEnumerator = [newUrlArray objectEnumerator];
                    NSMutableDictionary	*newUrl;

                    while( newUrl = [objectEnumerator nextObject] )
                    {
                        [self addUrlToSearchlist:newUrl];
                    }
                }
            }
        }
        deltatime = 10*[[url objectForKey:@"transfertime"] doubleValue];
        [searchSite setObject:[NSDate dateWithTimeIntervalSinceNow:deltatime] forKey:@"nextaccess"];
    }
    else
    {
        [searchSite setObject:[NSDate dateWithTimeIntervalSinceNow:1000.0] forKey:@"nextaccess"];
    }
    [allSitesSortedArray removeObject:searchSite];
    [allSitesSortedArray addObject:searchSite];
    if(! [searchSite objectForKey:@"ipaddress"] && [url objectForKey:@"ipaddress"] )
        [searchSite setObject:[url objectForKey:@"ipaddress"] forKey:@"ipaddress"];
    [url release];
}



- (void) runTheWriteToFileLoop;
{
    NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleWithStandardOutput];

    while(1)
    {
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        NSMutableDictionary *url;
        
        [writeToFileLock lockWhenCondition:CONDITION_QUEUE_NOT_EMPTY];
        url = [[writeToFileQueue objectAtIndex:0] retain];
        [writeToFileQueue removeObjectAtIndex:0];
        [writeToFileLock unlockWithCondition:[writeToFileQueue count]?CONDITION_QUEUE_NOT_EMPTY:CONDITION_QUEUE_EMPTY];

        if(  [[url objectForKey:@"HTTP"] hasPrefix:@"200"] && [[url objectForKey:@"content-type"] hasPrefix:@"text"] )
        {

            [fileHandle writeData:[@"\nURL:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"sitename"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                    allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"path"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                        allowLossyConversion:YES]];
            [fileHandle writeData:[@"\nCONTENTTYPE:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"content-type"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                allowLossyConversion:YES]];
            [fileHandle writeData:[@"\nCONTENT:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"contents"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                            allowLossyConversion:YES]];
        }
        [url release];
        [innerPool release];
    }
    [outerPool release];
    [NSThread exit];
}


- (NSString *)userAgentName;
{
    return userAgentName;
}
- (NSString *)userAgentMail;
{
    return userAgentMail;
}
- (NSMutableDictionary *)httpProxy;
{
    return httpProxy;
}

- (void)propertyListBecameInvalid:(NSNotification *)notificationObject;
{
    //NSLog(@"PropertyList was saved: %@",[notificationObject name]);
    //persistentSitesDictionary = [propertyList rootDictionary];
}

@end
