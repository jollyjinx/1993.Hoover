/* HooverController.m created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#import "HooverController.h"
#import "FetcherController.h"
#import "StageInformation.h"

#define ENTITY_NAME_SHOP	@"Shop"
#define ENTITY_NAME_SITE	@"Site"
#define ENTITY_NAME_PAGE	@"Page"
#define ENTITY_NAME_STAGE	@"StageInformation"

#define	FETCH_STATUS_TOFETCH	0
#define	FETCH_STATUS_FETCHING	1
#define	FETCH_STATUS_FETCHED	2

#define ROBOTS_REFETCH_TIME	864000.0
#define ROBOTS_PATH		@"/robots.txt"

#define	REFETCH_FACTOR		5.0
#define	FAILEDFETCH_MINIMUM_TIMETOWAIT	800.0
#define	FAILEDFETCH_MAXIMUM_TIMETOWAIT	300000.0
#define AVERAGE_PAGE_LOADTIME	5

@implementation HooverController : NSObject


- (void)dealloc
{
    [allSitesDatedQueue release];
    [sitesInformationDictionary release];
    [receivedUrlsQueue release];
    [fetcherController release];
    
    [super dealloc];
}


- (id)initWithConfiguration:(NSDictionary *)configurationDictionary;
{
    NSMutableDictionary *generalConfiguration;
    NSAutoreleasePool	*pool;

    [super init];

    pool			= [[NSAutoreleasePool alloc] init];
    allSitesDatedQueue		= [[AdvancedDatedQueue alloc] init];
    receivedUrlsQueue		= [[MTQueue alloc] init];
    sitesInformationDictionary	= [[NSMutableDictionary alloc] init];
    fetchedPagesDictionary	= [[NSMutableDictionary alloc] init];

    eofLock			= [[NSLock alloc] init];
    
    if( !(generalConfiguration = [configurationDictionary objectForKey:@"general"]) )
    {
        NSLog(@"HooverController: No 'general' Dictionary in configuration file.");
        return nil;
    }
    
    [EOModelGroup setDefaultGroup:[[[EOModelGroup alloc] init] autorelease]];
    [[EOModelGroup defaultGroup] addModelWithFile:[generalConfiguration objectForKey:@"eomodel"]];
    
    NSLog(@"HooverController init done - starting background threads.");
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



- (void)stageWorkLoop;
{
    NSDate	*stageEndDate = nil;

    while(1)
    {	
        NSAutoreleasePool	*stagePool = [[NSAutoreleasePool alloc] init];
        int			currentstage = 0;
       
        [eofLock lock];
        {
            NSAutoreleasePool 	*eoPool = [[NSAutoreleasePool alloc] init];
            
            EOEditingContext 	*eoEditingContext= [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];
            EODatabaseContext	*myDatabaseContext = [EODatabaseContext registeredDatabaseContextForModel:[[[EOModelGroup defaultGroup] models] lastObject]
                                                                                         editingContext: eoEditingContext];
            StageInformation 	*currentStage	= [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_STAGE qualifier:nil sortOrderings:nil]] lastObject];

            [eoEditingContext setUndoManager:nil];
            currentstage	= [currentStage currentStage];
            
            if( stageEndDate )
                [stageEndDate release];
            stageEndDate	= [NSDate dateWithTimeIntervalSinceNow:[currentStage stageIntervall]];
            [stageEndDate retain];

            NSLog(@"HooverController stageWorkLoop: Entering now Stage: %d",currentstage);
            {
                NSAutoreleasePool 	*sitePool = [[NSAutoreleasePool alloc] init];
                NSMutableDictionary	*aSite;
                EOAdaptorChannel 	*myChannel = [[myDatabaseContext availableChannel] adaptorChannel];

                [myChannel selectAttributes:[[[EOModelGroup defaultGroup] entityNamed: ENTITY_NAME_SITE] attributes]
                         fetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_SITE qualifier:nil sortOrderings:nil]
                                       lock:NO
                                     entity:[[EOModelGroup defaultGroup] entityNamed: ENTITY_NAME_SITE]];

                do
                {
                    NSAutoreleasePool 	*channelDataPool = [[NSAutoreleasePool alloc] init];

                    if( aSite = [myChannel fetchRowWithZone:NULL] )
                    {
                        NSMutableDictionary	*siteDictionary = [sitesInformationDictionary objectForKey:[aSite objectForKey:@"siteID"]];

                        if( nil == siteDictionary )
                        {
                            siteDictionary = [NSMutableDictionary dictionary];

                            [siteDictionary setObject:[aSite objectForKey:@"siteName"] forKey:@"host"];
                            [siteDictionary setObject:[aSite objectForKey:@"siteID"] forKey:@"siteid"];
                            [siteDictionary setObject:[aSite objectForKey:@"port"] forKey:@"port"];

                            if( [EONull class] != [[aSite objectForKey:@"robotsDate"] class] )
                                [siteDictionary setObject:[aSite objectForKey:@"robotsDate"] forKey:@"robotsdate"];
                            if( [EONull class] != [[aSite objectForKey:@"robotsData"] class] )
                                [siteDictionary setObject:[aSite objectForKey:@"robotsData"] forKey:@"robotsdata"];
                            
                            [siteDictionary setObject:[NSNumber numberWithInt:800.0] forKey:@"timetowait"];
                            [siteDictionary setObject:[NSMutableArray array] forKey:@"pages"];
                            [sitesInformationDictionary setObject:siteDictionary forKey:[aSite objectForKey:@"siteID"]];
                        }
                        else
                        {
                            [siteDictionary setObject:[NSMutableArray array] forKey:@"pages"];
                        }
                        [allSitesDatedQueue push:[siteDictionary objectForKey:@"siteid"] withDate:[NSDate distantPast]];
                    }
                    [channelDataPool release];
                }
                while( nil != aSite );
                [sitePool release];
            }
            NSLog(@"HooverController stageWorkLoop: Sites now %d",[allSitesDatedQueue count]);




            NSLog(@"HooverController stageWorkLoop: init pages");
            {
                NSAutoreleasePool 	*pagePool = [[NSAutoreleasePool alloc] init];

                EOAdaptorChannel 	*myChannel = [[myDatabaseContext availableChannel] adaptorChannel];
                NSMutableDictionary	*aPage;
                int pagecount=0;
                int throwcount=0;
                
                [myChannel selectAttributes:[[[EOModelGroup defaultGroup] entityNamed: ENTITY_NAME_PAGE] attributes]
                              fetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_PAGE
                                                                                              qualifier:[EOQualifier qualifierWithQualifierFormat:@"currentStage<=%d AND fetchStatus=%d AND doNotCrawl!=1",currentstage,FETCH_STATUS_TOFETCH]
                                                                                          sortOrderings:[NSArray arrayWithObjects:[EOSortOrdering sortOrderingWithKey:@"currentStage" selector:EOCompareAscending],nil]]
                                            lock:NO
                                          entity:[[EOModelGroup defaultGroup] entityNamed: ENTITY_NAME_PAGE]];


                do
                {
                    NSAutoreleasePool 	*channelDataPool = [[NSAutoreleasePool alloc] init];

                    if( aPage = [myChannel fetchRowWithZone:NULL] )
                    {
                        NSMutableDictionary	*siteDictionary = [sitesInformationDictionary objectForKey:[aPage objectForKey:@"siteid"]];
                        NSMutableArray		*pageArray = [siteDictionary objectForKey:@"pages"];

                        if( [pageArray count] <= ([currentStage stageIntervall]/AVERAGE_PAGE_LOADTIME) )
                        {
                            NSString		*fetchedStage;
                            NSMutableDictionary	*newPage = [NSMutableDictionary dictionaryWithObjectsAndKeys:[aPage objectForKey:@"pageid"],@"pageid",
                                                                                                      [aPage objectForKey:@"shopid"],@"shopid",
                                                                                                      [aPage objectForKey:@"siteid"],@"siteid",
                                                                                                      [aPage objectForKey:@"path"],@"path",
                                                                                                      [aPage objectForKey:@"currentStage"],@"currentStage",
                                nil];
                            if( [aPage objectForKey:@"linkdepth"] )
                                [newPage setObject:[aPage objectForKey:@"linkdepth"] forKey:@"linkdepth"];

                            if( nil == (fetchedStage = [fetchedPagesDictionary objectForKey:[aPage objectForKey:@"pageid"]]) )
                            {
                                [pageArray insertObject:newPage atIndex:0];
                            }
                            else
                            {
                                if( ! [fetchedStage isEqual:[aPage objectForKey:@"currentStage"]] )
                                {
                                    [pageArray insertObject:newPage atIndex:0];
                                }
                            }
                            if(0== ++pagecount%1000) NSLog(@"HooverController stageWorkLoop: added page no. %d",pagecount);
                        }
                        else
                        {
                            if(0== ++throwcount%1000) NSLog(@"HooverController stageWorkLoop: thrown away page no. %d",throwcount);
                        }
                    }
                    [channelDataPool release];
                }
                while(nil != aPage);
                [pagePool release];
            }


            [eoEditingContext invalidateAllObjects];
            [eoPool release];
            NSLog(@"HooverController stageWorkLoop: eoPool release done");
        }
        [eofLock unlock];

        NSLog(@"HooverController stageWorkLoop: entering the sendLoop now.");
        
        while( NSOrderedDescending == [stageEndDate compare:[NSDate date]] )
        {
            NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
            NSString		*siteId;
            
            if( siteId = [allSitesDatedQueue popBeforeDate:stageEndDate] )
            {
                NSMutableDictionary	*siteDictionary = [sitesInformationDictionary objectForKey:siteId];
               #if DEBUG
                NSLog(@"HooverController stageWorkLoop: Trying site : %@",siteDictionary);
                #endif

                if( ![siteDictionary objectForKey:@"robotsdata"] || (NSOrderedDescending == [(NSDate *)[NSDate dateWithTimeIntervalSinceNow:- ROBOTS_REFETCH_TIME] compare:[siteDictionary objectForKey:@"robotsdate"]]) )
                {
                    [fetcherController fetchLocalUrl:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [siteDictionary objectForKey:@"siteid"], @"siteid",
                        [siteDictionary objectForKey:@"host"],@"host",
                            [siteDictionary objectForKey:@"port"],@"port",
                            ROBOTS_PATH,@"path",
                        [NSNumber numberWithInt:10],@"crawltimefactor",
                        [NSNumber numberWithInt:1],@"crawltimeminimum",
                        [NSNumber numberWithInt:100000],@"crawltimemaximum",
                            nil]];
                }
                else
                {
                    NSMutableDictionary *aPage = [[siteDictionary objectForKey:@"pages"] lastObject];

                    if( aPage )
                    {
                        [aPage setObject:[siteDictionary objectForKey:@"siteid"] forKey:@"siteid"];
                        [aPage setObject:[siteDictionary objectForKey:@"host"] forKey:@"host"];
                        [aPage setObject:[siteDictionary objectForKey:@"port"] forKey:@"port"];

                        [aPage setObject:[NSNumber numberWithInt:1] forKey:@"crawltimeminimum"];
                        [aPage setObject:[NSNumber numberWithInt:10000] forKey:@"crawltimemaximum"];
                        [aPage setObject:[NSNumber numberWithInt:10] forKey:@"crawltimefactor"];

                        if( [siteDictionary objectForKey:@"robotsdata"] )	[aPage setObject:[siteDictionary objectForKey:@"robotsdata"] forKey:@"robotsdata"];
                        if( [siteDictionary objectForKey:@"ipaddress"] )		[aPage setObject:[siteDictionary objectForKey:@"ipaddress"] forKey:@"ipaddress"];

                        [fetcherController fetchLocalUrl:aPage];

                        [[siteDictionary objectForKey:@"pages"] removeLastObject];
                    }
                    else
                    {
                        NSLog(@"HooverController stageWorkLoop: popped site with no work: siteID=%@ currentStage=%d", [siteDictionary objectForKey:@"siteid"],currentstage);
                    }
                }
            }
            else
            {
                NSLog(@"HooverController stageWorkLoop: queue was empty while stage increased");
            }
            [innerPool release];
        }
        
        [eofLock lock];
        {
            EOEditingContext 	*eoEditingContext= [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];
            StageInformation 	*currentStage	= [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_STAGE qualifier:nil sortOrderings:nil]] lastObject];

            [currentStage setCurrentStage:[currentStage currentStage]+1];
            [eoEditingContext saveChanges];
        }
        [eofLock unlock];
        [stagePool release];
    }//while(1)
        
}


- (void)retrievedUrl:(NSMutableDictionary *)url;
{
    #if DEBUG
    NSLog(@"HooverController retrievedUrl:%@",url);
    #endif
    [receivedUrlsQueue push:url];
}

- (void)runTheRetrievingThread;
{
    while(1)
    {
        NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
        NSMutableDictionary	*url	= [receivedUrlsQueue pop];
        NSMutableDictionary	*siteDictionary = [sitesInformationDictionary objectForKey:[url objectForKey:@"siteid"]];

        NSAssert1( nil != siteDictionary, @"HooverController runTheRetrievingThread: Site Dictionary for %@ not there",url );

        if(! [[url objectForKey:@"status"] isEqual:@"invalid"] )		// possible stati : invalid,fetched,redirected
        {
            if( [[url objectForKey:@"path"] isEqual:ROBOTS_PATH] )		// if it's a robots.txt then remember the robots data and the ipaddress
            {
                EOEditingContext	*eoEditingContext;
                EOGenericRecord		*eoSite;

                [eofLock lock];
                eoEditingContext= [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];
                [eoEditingContext setUndoManager:nil];
                eoSite = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_SITE
                                                                                                                              qualifier:[EOQualifier qualifierWithQualifierFormat:@"siteID = %@",[url objectForKey:@"siteid"]]
                                                                                                                          sortOrderings:nil]] lastObject];
                if( nil == eoSite )
                {
                    NSLog(@"HooverController runTheRetrievingThread: got Url for Site where the site is no longer in the database : %@",[url description]);
                }
                else
                {
                    if( [[url objectForKey:@"robotsdata"] length] > 8000 )
                    {
                        NSLog(@"Robots Data exceeds limit for url: %@ ",url);
                    }
                    else
                    {
                        [eoSite takeValue:[url objectForKey:@"robotsdata"] forKey:@"robotsData"];
                    }
                    [eoSite takeValue:[url objectForKey:@"transferdate"] forKey:@"robotsDate"];
                    [siteDictionary setObject:[url objectForKey:@"ipaddress"] forKey:@"ipaddress"];
                    [siteDictionary setObject:[url objectForKey:@"transferdate"] forKey:@"robotsdate"];
                    [siteDictionary setObject:[url objectForKey:@"robotsdata"] forKey:@"robotsdata"];

                    [allSitesDatedQueue push:[siteDictionary objectForKey:@"siteid"] withDate:[[url objectForKey:@"transferdate"] addTimeInterval:REFETCH_FACTOR*[[url objectForKey:@"transfertime"] floatValue]]];

                    {
                        BOOL savedflag = NO;
                        NS_DURING
                            [eoEditingContext saveChanges];
                            savedflag=YES;
                        NS_HANDLER
                            NSLog(@"%@.%@1.Exception url:%@",[localException name],[localException reason],[url description]);
                        NS_ENDHANDLER

                        NS_DURING
                            if( NO==savedflag)
                            {
                                NSLog(@"HooverController: - runTheRetrievingThread: saving failed trying again.");
                                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
                                [eoEditingContext saveChanges];
                            }
                        NS_HANDLER
                            NSLog(@"%@.%@2.Exception url:%@",[localException name],[localException reason],[url description]);
                        NS_ENDHANDLER
                    }
                }
                [eofLock unlock];
            }
            else
            {
                NSTimeInterval	timetowait =  [[url objectForKey:@"crawltimefactor"] doubleValue]*[[url objectForKey:@"transfertime"] doubleValue];

                //NSLog(@"HooverController runTheRetrievingThread: Got page %@ for site %@ have %d",[url objectForKey:@"pageid"],[url objectForKey:@"shopid"],[fetchedPagesDictionary count]);
                [fetchedPagesDictionary setObject:[url objectForKey:@"currentStage"] forKey:[url objectForKey:@"pageid"]];	// @"!" is just a short constant string
                
                if( timetowait < [[url objectForKey:@"crawltimeminimum"] doubleValue] )
                {
                    timetowait = [[url objectForKey:@"crawltimeminimum"] doubleValue];
                }
                else if( timetowait > [[url objectForKey:@"crawltimemaximum"] doubleValue] )
                {
                    timetowait = [[url objectForKey:@"crawltimemaximum"] doubleValue];
                }

                [allSitesDatedQueue push:[siteDictionary objectForKey:@"siteid"] withDate:[[url objectForKey:@"transferdate"] addTimeInterval:timetowait]];
            }
        }
        else // invalid status
        {
            NSTimeInterval timetowait = [[siteDictionary objectForKey:@"timetowait"] floatValue] * 2.0;

            if( timetowait < [[url objectForKey:@"crawltimeminimum"] doubleValue] )
            {
                timetowait = [[url objectForKey:@"crawltimeminimum"] doubleValue];
            }
            else if( timetowait > [[url objectForKey:@"crawltimemaximum"] doubleValue] )
            {
                timetowait = [[url objectForKey:@"crawltimemaximum"] doubleValue];
            }

            [allSitesDatedQueue push:[siteDictionary objectForKey:@"siteid"] withDate:[NSDate dateWithTimeIntervalSinceNow:timetowait]];
        }
        [pool release];
    }
}


- (void)save;
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"HooverController: -save");
//    NSLog(@"HooverController: database saved");

    [pool release];
    exit(1);
}

- (void)showCurrentStatus;
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"HooverController: showCurrentStatus: receivedQueue count %d.",[receivedUrlsQueue count]);
    NSLog(@"HooverController: showCurrentStatus: sendQueue count %d.",[fetcherController count]);
    NSLog(@"HooverController: showCurrentStatus: allSitesDatedQueue count %d.",[allSitesDatedQueue count]);
    NSLog(@"HooverController: showCurrentStatus: fetchedPagesDictionary count %d.",[fetchedPagesDictionary count]);
    [pool release];
}

@end




