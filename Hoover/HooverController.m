/* HooverController.m created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#import "HooverController.h"
#import "FetcherController.h"
#import "RobotScanner.h"

#define QUICK_CRAWL 	0
#define SKIP_ROBOTS_TXT	0

#if QUICK_CRAWL
    #warning Using Quickcrawl.
    #define GDBMCACHE_TIME		1000.0					// time it takes till an unused site will be stored to the harddisk
    #define TRANSFER_TIME_FACTOR	0.01					// how long should we wait when the site answered - gets multiplied by the transfertime
    #define N_TIMES_FAILED_FACTOR	2.0 					// how long should we wait when a site failed once more
    #define FIRSTFAIL_TIME		800.0					// how long should we wait when a site failed to load the first time
    #define MAXIMUM_RETRY_TIME		100000.0				// maximum time a site will be unvisited even if we never connected to it
    #define MINIMUM_RETRY_TIME		1.0					// mimimum time a site will be left alone 
    #define MAXIMUM_URL_LENGTH		10000						
#else
    #define GDBMCACHE_TIME		1000.0					// time it takes till an unused site will be stored to the harddisk
    #define TRANSFER_TIME_FACTOR	10					// how long should we wait when the site answered - gets multiplied by the transfertime
    #define N_TIMES_FAILED_FACTOR	2.0					// how long should we wait when a site failed once more
    #define FIRSTFAIL_TIME		800.0					// how long should we wait when a site failed to load the first time
    #define MAXIMUM_RETRY_TIME		100000.0				// maximum time a site will be unvisited even if we never connected to it
    #define MINIMUM_RETRY_TIME		10.0					// mimimum time a site will be left alone 
    #define MAXIMUM_URL_LENGTH		10000						
#endif



#ifdef NeXT
#import <mach/cthreads.h>
#endif

@interface NSThread(threadExtendedMethods)
+ (int)setPriority:(int)newpriority;
@end

@implementation NSThread(threadExtendedMethods)

+ (int)setPriority:(int)newpriority;
{
#ifdef NeXT
    struct thread_sched_info  info;
    unsigned int              info_count=THREAD_SCHED_INFO_COUNT;
    
    cthread_priority(cthread_self(),newpriority,FALSE);
    if( KERN_SUCCESS != thread_info(thread_self(), THREAD_SCHED_INFO, (thread_info_t)&info, &info_count) )
    {
        NSLog(@"Can't get priority of thread");
        return -1;
    }
    return info.cur_priority;
#else
    NSLog(@"Seting of scheduling parameters not supported on this platform.");
    return -1;
#endif
}
@end


@implementation HooverController : NSObject


- (void)dealloc
{
    [gdbmCache release];
    [receivedUrlsQueue release];
    [fetcherController release];
    [allSitesDatedQueue release];
    [siteLock release];
    [super dealloc];
}

- (void)readURLsFromStdinFilehandle;
{
    FILE			*stdinstream = fdopen(0,"r");
    static char		linebuffer[MAXIMUM_URL_LENGTH];
    //int				counter = 0;

    NSLog(@"HooverController - readURLsFromStdinFilehandle: begin.");

    while( !feof(stdinstream) )
    {
        if( NULL != fgets(linebuffer, MAXIMUM_URL_LENGTH-1, stdinstream) )
        {
            NSAutoreleasePool 	*innerPool = [[NSAutoreleasePool alloc] init];
            NSMutableDictionary	*aLink=nil;

            linebuffer[strlen(linebuffer)-1]=0;
            if( aLink = [HTMLScanner getDictionaryFromURL:[NSString stringWithCString:linebuffer] baseUrl:nil] )
            {
                [self addUrlToSearchlist:aLink freePath:YES];
            }

            while( [fetcherController count] > 30 )		// keep the Hoover not to busy just loading robot.txt files
            {
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            }
            //if( 0 == (counter++ %10) )
            //    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            [innerPool release];
        }
    }
    fclose(stdinstream);
    NSLog(@"HooverController - readURLsFromStdinFilehandle: end.");
    [NSThread exit];
}

- (id)initWithConfiguration:(NSDictionary *)configurationDictionary;
{
    NSMutableDictionary *generalConfiguration;
    NSAutoreleasePool	*pool;
    GDBMFile		*gdbmFile;

    [super init];

    followlinks		= NO;
    stayonsites		= YES;
    allpathsallowed	= NO;
    maximumlinkdepth	= 0;


    
    pool		= [[NSAutoreleasePool alloc] init];
    receivedUrlsQueue	= [[MTQueue alloc] init];
    allSitesDatedQueue	= [[DatedQueue alloc] init];
    siteLock		= [[NSLock alloc] init];
    
    if( !(generalConfiguration = [configurationDictionary objectForKey:@"general"]) )
    {
        NSLog(@"HooverController: No 'general' Dictionary in configuration file.");
        return nil;
    }
    if([generalConfiguration objectForKey:@"followlinks"])
    {
        followlinks = (NSOrderedSame==[[generalConfiguration objectForKey:@"followlinks"] caseInsensitiveCompare:@"Yes"]?YES:NO);
    }
    NSLog(@"HooverController: Follow links: %@",(followlinks?@"Yes":@"No"));

    if([generalConfiguration objectForKey:@"stayonsites"])
    {
        stayonsites = (NSOrderedSame==[[generalConfiguration objectForKey:@"stayonsites"] caseInsensitiveCompare:@"Yes"]?YES:NO);
    }
    NSLog(@"HooverController: Stay on sites: %@",(stayonsites?@"Yes":@"No"));

    if([generalConfiguration objectForKey:@"allpathsallowed"])
    {
        allpathsallowed = (NSOrderedSame==[[generalConfiguration objectForKey:@"allpathsallowed"] caseInsensitiveCompare:@"Yes"]?YES:NO);
    }
    NSLog(@"HooverController: All Paths allowed: %@",(allpathsallowed?@"Yes":@"No"));

    if([generalConfiguration objectForKey:@"maximumlinkdepth"])
    {
        maximumlinkdepth = [[generalConfiguration objectForKey:@"maximumlinkdepth"] intValue];
    }
    NSLog(@"HooverController: Follow links to depth: %@",(maximumlinkdepth?[[NSNumber numberWithInt:maximumlinkdepth] description]:@"indefenitly"));


    if( !(gdbmFile = [GDBMFile gdbmFileWithPath:[generalConfiguration objectForKey:@"databasename"] create:YES readOnly:NO]) )    
    {
        NSLog(@"HooverController: Couldn't create GDBMFile with database: %@", [generalConfiguration objectForKey:@"databasename"]);
        return nil;
    }
    NSLog(@"GDBMFile opened");

    if( [gdbmFile isEmpty] )											// first use of program
    {
        NSMutableDictionary	*urls;
        NSEnumerator		*objectEnumerator;
        NSString		*urlString;
        NSMutableDictionary	*urlDictionary;

        NSLog(@"HooverController: Database empty.");
        
        if( !(gdbmCache = [[GDBMCache gdbmCacheWithGDBMFile:gdbmFile] retain]) )
        {
            NSLog(@"HooverController: Couldn't create GDBMCache with GDBMFile object.");
            return nil;
        }
        
        if( !(urls = [configurationDictionary objectForKey:@"urls"]) )
        {
            NSLog(@"HooverController: No 'urls' Dictionary in configuration file, using stdin for reading urls.");
            [NSThread detachNewThreadSelector:@selector(readURLsFromStdinFilehandle)
                                     toTarget:self
                                   withObject:nil];

        }
        else
        {
            objectEnumerator = [urls objectEnumerator];
            while( urlString = [objectEnumerator nextObject] )
            {
                NSAutoreleasePool *urlReadPool = [[NSAutoreleasePool alloc] init];

                if( urlDictionary = [HTMLScanner getDictionaryFromURL:urlString baseUrl:nil] )
                {
                    [self addUrlToSearchlist:urlDictionary freePath:YES];
                }
                [urlReadPool release];
            }
        }
    }
    else
    {
        NSEnumerator		*keyEnumerator = [gdbmFile keyEnumerator];
        id					siteName;
        unsigned int		allsitescount=0;
        NSMutableDictionary	*urls;
        
        NSLog(@"HooverController: Begin reading database file.");
        while( siteName = [keyEnumerator nextObject] )
        {
            NSAutoreleasePool 	*innerPool = [[NSAutoreleasePool alloc] init];
            NSMutableDictionary	*persistentSite = [gdbmFile objectForKey:siteName];

            allsitescount++;
            #if DEBUG
                NSLog(@"HooverController: Loading site: %@",siteName);	// we don't have to test the site anymore
                NSLog(@"HooverController: Site contents: %@",[persistentSite description]);
            #endif
            if( persistentSite )
            {
                if( [[persistentSite objectForKey:@"unknownpaths"] count])
                {
                    NSDate *nextAccessDate = [persistentSite objectForKey:@"nextaccess"];

                    if( ! nextAccessDate )
                    {
                        nextAccessDate = [NSDate distantPast];
                    }
                    [allSitesDatedQueue push:siteName withDate:nextAccessDate];
                }
            }
            else
            {
                NSLog(@"HooverController: found invalid site in database:%@",[persistentSite description]);
            }
            [innerPool release];
        }
        NSLog(@"HooverController: Found %d sites in persistent property list.",allsitescount);
        NSLog(@"HooverController: Found %d sites in persistent property list that have unkown urls",[allSitesDatedQueue count]);

        
        if( urls = [configurationDictionary objectForKey:@"urls"] )
        {
            NSEnumerator 	*objectEnumerator;
            NSString		*urlString;
            NSMutableDictionary	*urlDictionary;
            
            NSLog(@"Even though we have a database: adding %d urls from configuration file.",[urls count]);
            objectEnumerator = [urls objectEnumerator];
            while( urlString = [objectEnumerator nextObject] )
            {
                NSAutoreleasePool *urlReadPool = [[NSAutoreleasePool alloc] init];
                
                if( urlDictionary = [HTMLScanner getDictionaryFromURL:urlString baseUrl:nil] )
                {
                    [self addUrlToSearchlist:urlDictionary freePath:YES];
                }

                [urlReadPool release];
            }
        }


        
        if( !(gdbmCache = [[GDBMCache gdbmCacheWithGDBMFile:gdbmFile] retain]) )
        {
            NSLog(@"HooverController: Couldn't create GDBMCache with GDBMFile object.");
            return nil;
        }
    }
    [gdbmCache setCacheLife:(NSTimeInterval)GDBMCACHE_TIME];


    fetcherController = [[FetcherController alloc] init];
    [NSThread detachNewThreadSelector:@selector(runWithHooverController:)
                             toTarget:fetcherController
                           withObject:self];
    [NSThread detachNewThreadSelector:@selector(runTheRetrievingThread)
                             toTarget:self
                           withObject:nil];
    [pool release];
    
    return self;
}


- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl
{
    [self addUrlToSearchlist:newUrl freePath:allpathsallowed];
}

- (void)addUrlToSearchlist:(NSMutableDictionary *)newUrl freePath:(BOOL)freepath
{
    NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary		*persistentSite;											// persistent Site is persistent and contains known/ unknown information
    NSString			*siteName;

    
    if( maximumlinkdepth && (maximumlinkdepth < [[newUrl objectForKey:@"linkdepth"] intValue]) )
    {
        #if DEBUG
        NSLog(@"Link too deep: %@",newUrl);
        #endif DEBUG
        return;
    }
    siteName = [NSString stringWithFormat:@"%@:%@",[newUrl objectForKey:@"host"],[newUrl objectForKey:@"port"]];
    
    if( persistentSite = [gdbmCache objectForKey:siteName] )
    {
        RobotScanner *robotScanner;
        if( (!(robotScanner = [persistentSite objectForKey:@"robotScanner"])) || [robotScanner urlIsWanted:newUrl] )
        {
            NSString *newPath = [newUrl objectForKey:@"path"];
            
            [siteLock lock];
            if( (![[persistentSite objectForKey:@"knownpaths"] objectForKey:newPath])
                && (![[persistentSite objectForKey:@"unknownpaths"] objectForKey:newPath]) )
            {
                BOOL pathisok = YES;
                
                if(!freepath)
                {
                    NSString		*checkPath;
                    NSEnumerator	*pathEnumerator = [[persistentSite objectForKey:@"knownpaths"] keyEnumerator];

                    pathisok = NO;
                    
                    while( !pathisok && (checkPath = [pathEnumerator nextObject]) )
                    {
                        if( NSOrderedSame != [@"/robots.txt" compare:checkPath]
                            && [newPath hasPrefix:[[checkPath stringByAppendingString:@"non"] stringByDeletingLastPathComponent]] )
                        {
                            //NSLog(@"HooverController :Prefix found %@ is in %@(%@)", newPath,checkPath,[checkPath stringByDeletingLastPathComponent]);
                            pathisok = YES;
                            break;
                        }
                    }
                    pathEnumerator = [[persistentSite objectForKey:@"unknownpaths"] keyEnumerator];
                    while( !pathisok && (checkPath = [pathEnumerator nextObject]) )
                    {
                        if( NSOrderedSame != [@"/robots.txt" compare:checkPath]
                            && [newPath hasPrefix:[[checkPath stringByAppendingString:@"non"] stringByDeletingLastPathComponent]] )
                        {
                            pathisok = YES;
                            //NSLog(@"HooverController :Prefix found %@ is in %@(%@)", newPath,checkPath,[checkPath stringByDeletingLastPathComponent]);
                            break;
                        }
                    }
                }

                if( pathisok )
                {
                    [[persistentSite objectForKey:@"unknownpaths"] setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:newPath,@"path",[newUrl objectForKey:@"linkdepth"],@"linkdepth",nil]
                                                                    forKey:newPath];
                    if(1 == [[persistentSite objectForKey:@"unknownpaths"] count])
                    {
                        NSLog(@"HooverController: site %@ has unknown urls again",siteName);
                        [allSitesDatedQueue push:siteName withDate:[persistentSite objectForKey:@"nextaccess"]];
                    }
                }
            }
            [siteLock unlock];
        }
        #if DEBUG
        else
        {
            NSLog(@"HooverController: RobotScanner rejects Url: %@",[newUrl description]);
        }
        #endif
    }
    else
    {															// in case the site is unknown create
        persistentSite = [NSMutableDictionary dictionary];								// persistent and sortedArray entries
        [persistentSite setObject:siteName forKey:@"sitename"];
        [persistentSite setObject:[newUrl objectForKey:@"host"] forKey:@"host"];
        [persistentSite setObject:[newUrl objectForKey:@"port"] forKey:@"port"];
        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"unknownpaths"];
        [persistentSite setObject:[NSMutableDictionary dictionary] forKey:@"knownpaths"];
        [[persistentSite objectForKey:@"unknownpaths"] setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[newUrl objectForKey:@"path"],@"path",[newUrl objectForKey:@"linkdepth"],@"linkdepth",nil]
                                                          forKey:[newUrl objectForKey:@"path"]];
        [gdbmCache setObject:persistentSite forKey:siteName];
        [allSitesDatedQueue push:siteName withDate:[NSDate date]];
    }
    [pool release];
}



- (void)putWorkInSendingUrlsQueue;
{
    //[NSThread setPriority:9];
    while(1)
    {	
        NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
        NSString			*siteName;
        NSMutableDictionary 		*persistentSite;
        NSMutableDictionary		*unknownDictionary;
        NSMutableDictionary		*url;

        siteName = [allSitesDatedQueue pop];

        persistentSite = [gdbmCache objectForKey:siteName];
        unknownDictionary = [persistentSite objectForKey:@"unknownpaths"];

        url = nil;												// 'hmmm work to do
        [siteLock lock];
        #if SKIP_ROBOTS_TXT
        #warning Skipping Robots.
        #else
            if( ! [[persistentSite objectForKey:@"knownpaths"] objectForKey:@"/robots.txt"] )			// in case we don't have the /robots.txt fetch it
            {
                url = [NSMutableDictionary dictionaryWithObject:@"/robots.txt" forKey:@"path"];
            }
            else
        #endif
        {
            if( 0 == [unknownDictionary count] )								// in case we know the whole site
            {													// we won't visit it again ( except we get new urls )
                #if DEBUG
                    NSLog(@"HooverController: site %@ has no unknown urls right now.",siteName);
                #endif
            }
            else
            {													// we have some file to fetch,
                url = [NSMutableDictionary dictionaryWithDictionary:[[unknownDictionary objectEnumerator] nextObject]];
            }
        }
        [siteLock unlock];

        NSAssert(nil != url,@"Url==nil" );
        
        {
            NSString	*ipaddress;
            [url setObject:siteName forKey:@"sitename"];
            [url setObject:@"http" forKey:@"method"];
            [url setObject:[persistentSite objectForKey:@"host"] forKey:@"host"];
            [url setObject:[persistentSite objectForKey:@"port"] forKey:@"port"];
            if( ipaddress = [persistentSite objectForKey:@"ipaddress"] )
                [url setObject:ipaddress forKey:@"ipaddress"];

            [fetcherController fetchLocalUrl:url];
        }
        [pool release];
    }
}



- (void)retrievedUrl:(NSMutableDictionary *)url;
{
    [receivedUrlsQueue push:url];
}




- (void)runTheRetrievingThread;
{
    [NSThread setPriority:15];
    while(1)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self workOnReceivedUrlsQueue];
        [pool release];
    }
}

- (void)workOnReceivedUrlsQueue;
{
    NSMutableDictionary	*url;
    double 				deltatime;
    NSString			*siteName;
    NSString			*urlPath;
    NSMutableDictionary	*persistentSite;
    NSMutableDictionary *persistentUrl;

    url 		= [receivedUrlsQueue pop];
    siteName		= [url objectForKey:@"sitename"];
    urlPath		= [url objectForKey:@"path"];
    persistentSite	= [gdbmCache objectForKey:siteName];

    #if DEBUG
        NSLog(@"HooverController: receivedQueue has %d items.",[receivedUrlsQueue count]);
        NSLog(@"HooverController: popped %@%@ %@",siteName,urlPath,[url objectForKey:@"status"]);
        NSLog(@"Got url:%@",[url description]);
    #endif
    


    if(! [[url objectForKey:@"status"] isEqual:@"invalid"] )							// fetched or redirected
    {
        if( [@"/robots.txt" isEqual:urlPath] )									// url is 'robots.txt' so instanciate a
        {													// robotScanner and save the 'robots.txt'
            if( [url objectForKey:@"httpdata"] )									// persistent
            {
                RobotScanner *robotScanner;

                if( robotScanner = [RobotScanner robotScannerWithUrl:url] )
                {
                    [persistentSite setObject:robotScanner forKey:@"robotScanner"];				// recheck every url do not know on that site
                    [siteLock lock];
                    [[persistentSite objectForKey:@"unknownpaths"] removeObjectsForKeys:[robotScanner unwantedPaths:[persistentSite objectForKey:@"unknownpaths"]]];
                    [siteLock unlock];
                }
            }
        }
        else
        {
            NSArray *linkArray;

           
            if( followlinks && (linkArray = [url objectForKey:@"links"]) )							// url contains links - so add them
            {
                NSEnumerator		*objectEnumerator = [linkArray objectEnumerator];
                NSMutableDictionary	*newUrl;
                
                while( newUrl = [objectEnumerator nextObject] )
                {
                    if(stayonsites)
                    {
                        if( (NSOrderedSame == [(NSString *)[url objectForKey:@"host"] compare:(NSString *)[newUrl objectForKey:@"host"]])
                            || (NSOrderedSame == [(NSString *)[url objectForKey:@"ipaddress"] compare:(NSString *)[newUrl objectForKey:@"host"]] ) )
                            [self addUrlToSearchlist:newUrl];
                    }
                    else
                    {
                        [self addUrlToSearchlist:newUrl];
                    }
                }
            }
        }

        persistentUrl = [NSMutableDictionary dictionaryWithObject:urlPath forKey:@"path"];
        [persistentUrl setObject:[url objectForKey:@"status"] forKey:@"status"];
        
        [[persistentSite objectForKey:@"knownpaths"] setObject:persistentUrl forKey:urlPath];			// url 'fetched' so it is known
        [[persistentSite objectForKey:@"unknownpaths"] removeObjectForKey:urlPath];				// url now known - so remove it from unknown

        if( ![url objectForKey:@"transfertime"] )
        {
            NSLog(@"HooverController: url has no transfertimekey:%@ ( using .01 second )",[url description]);
            deltatime=.01;
        }
        else
        {
            deltatime = (double)TRANSFER_TIME_FACTOR * [[url objectForKey:@"transfertime"] doubleValue];
        }
        
        if( deltatime < MINIMUM_RETRY_TIME )
        {
            deltatime = MINIMUM_RETRY_TIME;
        }
        else if( deltatime > MAXIMUM_RETRY_TIME )
        {
            deltatime = MAXIMUM_RETRY_TIME;
        }

        [persistentSite setObject:[NSDate dateWithTimeIntervalSinceNow:deltatime] forKey:@"nextaccess"];
        [persistentSite removeObjectForKey:@"failedaccess"];
    }
    else
    {
        NSDate *failedAccessDate = [persistentSite objectForKey:@"failedaccess"];
        NSString *errorreason = [url objectForKey:@"errorreason"];
        
        if(! failedAccessDate )
        {
            NSLog(@"HooverController: site %@ failed the first time (%@)",siteName, errorreason);
            [persistentSite setObject:[NSDate dateWithTimeIntervalSinceNow:FIRSTFAIL_TIME] forKey:@"nextaccess"];
        }
        else
        {
            NSLog(@"HooverController:  site %@ failed again (%@)",siteName, errorreason);
            [persistentSite setObject:[NSDate dateWithTimeIntervalSinceNow:-N_TIMES_FAILED_FACTOR*[failedAccessDate timeIntervalSinceNow]]
                               forKey:@"nextaccess"];
        }
        [persistentSite setObject:[NSDate date] forKey:@"failedaccess"];
    }

    if(! [persistentSite objectForKey:@"ipaddress"] && [url objectForKey:@"ipaddress"] )
        [persistentSite setObject:[url objectForKey:@"ipaddress"] forKey:@"ipaddress"];

    //NSLog(@"Persistent site now:%@",[persistentSite description]);

    [siteLock lock];
    if( [[persistentSite objectForKey:@"unknownpaths"] count] )
    {
        NSLog(@"HooverController: site %@ has next access:%@",siteName ,[persistentSite objectForKey:@"nextaccess"]);
        [allSitesDatedQueue push:siteName withDate:[persistentSite objectForKey:@"nextaccess"]];
    }
    else
    {
        NSLog(@"HooverController: site %@ has no unknown urls now.",siteName);
    }
    [siteLock unlock];

}


- (void)save;
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"HooverController: -save");
    [gdbmCache save];
    NSLog(@"HooverController: database saved");
    exit(1);
    [pool release];
}

- (void)showCurrentStatus;
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"HooverController: showCurrentStatus: receivedQueue count %d.",[receivedUrlsQueue count]);
    NSLog(@"HooverController: showCurrentStatus: sendQueue count %d.",[fetcherController count]);
    NSLog(@"HooverController: showCurrentStatus: allSitesDatedQueue count %d.",[allSitesDatedQueue count]);
    NSLog(@"HooverController: showCurrentStatus: gdbmCache cacheCount %d.",[gdbmCache cacheCount]);
    [pool release];
}

@end




