/* HooverController.m created by jolly on Sat 01-Mar-1997 */

#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#import "HooverController.h"
#import "FetcherController.h"
#import "StageInformation.h"
#import "Page.h"
#import "Site.h"

#define ENTITY_NAME_SHOP	@"Shop"
#define ENTITY_NAME_SITE	@"Site"
#define ENTITY_NAME_PAGE	@"Page"
#define ENTITY_NAME_STAGE	@"StageInformation"

#define	FETCH_STATUS_TOFETCH	0
#define	FETCH_STATUS_FETCHING	1
#define	FETCH_STATUS_FETCHED	2

#define ROBOTS_REFETCH_TIME	86400.0
#define ROBOTS_PATH		@"/robots.txt"

#define	REFETCH_FACTOR		10.0
#define	FAILEDFETCH_MINIMUM_TIMETOWAIT	800.0
#define	FAILEDFETCH_MAXIMUM_TIMETOWAIT	300000.0

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
    allSitesDatedQueue		= [[DatedQueue alloc] init];
    receivedUrlsQueue		= [[MTQueue alloc] init];
    sitesInformationDictionary	= [[NSMutableDictionary alloc] init];
    
    if( !(generalConfiguration = [configurationDictionary objectForKey:@"general"]) )
    {
        NSLog(@"HooverController: No 'general' Dictionary in configuration file.");
        return nil;
    }
    
    [EOModelGroup setDefaultGroup:[EOModelGroup new]];
    [[EOModelGroup defaultGroup] addModelWithFile:[generalConfiguration objectForKey:@"eomodel"]];

    if(! (shopClassDescription  = [[EOClassDescription classDescriptionForEntityName:ENTITY_NAME_SHOP] retain]) )
    {
        NSLog(@"Coudn't get classDescription for Entity:%@",ENTITY_NAME_SHOP);
        return nil;
    }
    if(! (siteClassDescription  = [[EOClassDescription classDescriptionForEntityName:ENTITY_NAME_SITE] retain]) )
    {
        NSLog(@"Coudn't get classDescription for Entity:%@",ENTITY_NAME_SITE);
        return nil;
    }
    if(! (pageClassDescription  = [[EOClassDescription classDescriptionForEntityName:ENTITY_NAME_PAGE] retain]) )
    {
        NSLog(@"Coudn't get classDescription for Entity:%@",ENTITY_NAME_PAGE);
        return nil;
    }
    if(! (stageClassDescription  = [[EOClassDescription classDescriptionForEntityName:ENTITY_NAME_STAGE] retain]) )
    {
        NSLog(@"Coudn't get classDescription for Entity:%@",ENTITY_NAME_STAGE);
        return nil;
    }

    // Set all open Pages (fetchStatus != FETCH_STATUS_TOFETCH ) that might still be in the database due to Hoover-crash to TOFETCH that we try those again
    {
        EOEditingContext	*eoEditingContext = [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];
        NSEnumerator		*pageEnumerator = [[eoEditingContext objectsWithFetchSpecification:
            [EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_PAGE
                                                                  qualifier:[EOQualifier qualifierWithQualifierFormat:@"fetchStatus==%d",FETCH_STATUS_FETCHING]
                                                              sortOrderings:nil]
												] objectEnumerator];
        Page *eoPage;	

        while( eoPage = [pageEnumerator nextObject] )
        {
            NSLog(@"Updateing fetchStatus in database for Page: %d",[eoPage pageID]);
            [eoPage setFetchStatus:0];
        }
        [eoEditingContext saveChanges];
    }
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
    while(1)
    {	
        NSAutoreleasePool	*stagePool = [[NSAutoreleasePool alloc] init];
        EOEditingContext	*eoEditingContext = [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];
        StageInformation	*currentStage = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_STAGE qualifier:nil sortOrderings:nil]] lastObject];
        NSDate			*stageEndDate= [NSDate dateWithTimeIntervalSinceNow:[currentStage stageIntervall]];

        {
            NSEnumerator *siteEnumerator = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_SITE qualifier:nil sortOrderings:nil]] objectEnumerator];
            Site *eoSite;

            while( eoSite = [siteEnumerator nextObject] )
            {
                [allSitesDatedQueue push:[NSNumber numberWithInt:[eoSite siteID]] withDate:[NSDate distantPast]];
            }
        }

        while( NSOrderedDescending == [stageEndDate compare:[NSDate date]] )
        {
            NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
            NSNumber			*siteidNumber;
            
            if( siteidNumber = [allSitesDatedQueue popBeforeDate:stageEndDate] )
            {
                Site *eoSite = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_SITE
                                                                                                                             qualifier:[EOQualifier qualifierWithQualifierFormat:@"siteID = %@",siteidNumber]	
                                                                                                                         sortOrderings:nil]] lastObject];
                if( nil == eoSite )
                {
                    NSLog(@"HooverController stageWorkLoop: got siteID %@ which is no longer in the database.");
                }
                else
                {
                    if( ![eoSite robotsDate] || (NSOrderedDescending == [(NSDate *)[NSDate dateWithTimeIntervalSinceNow:- ROBOTS_REFETCH_TIME] compare:[eoSite robotsDate]]) )
                    {
                        [fetcherController fetchLocalUrl:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:[eoSite siteID]], @"siteid",
                            [eoSite siteName],@"host",
                            [NSNumber numberWithInt:[eoSite port]],@"port",
                            ROBOTS_PATH,@"path",
                            nil]];
                    }
                    else
                    {
                        Page *eoPage = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_PAGE
                                                                                                                                     qualifier:[EOQualifier qualifierWithQualifierFormat:
																		@"siteID=%d AND currentStage<=%d AND fetchStatus=%d ",
																		[siteidNumber intValue],[currentStage currentStage],FETCH_STATUS_TOFETCH]
                                                                                                                                 sortOrderings:[NSArray arrayWithObjects:[EOSortOrdering sortOrderingWithKey:@"currentStage" selector:EOCompareDescending],nil]]
                            ] lastObject];


                        if( nil != eoPage )
                        {
                            NSMutableDictionary *newUrl = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:[eoSite siteID]],@"siteid",
                                [NSNumber numberWithInt:[eoPage pageID]], @"pageid",
                                [NSNumber numberWithInt:[eoPage shopID]],@"shopid",
                                [eoSite siteName],@"host",
                                [NSNumber numberWithInt:[eoSite port]],@"port",
                                [eoPage path],@"path",
                                nil];
                            if( [eoSite robotsData] ) 		[newUrl setObject:[eoSite robotsData] forKey:@"robotsdata"];
                            if( [eoPage lastDownloaded] ) 	[newUrl setObject:[eoPage lastDownloaded] forKey:@"lastmodified"];
                            if( [eoPage followLinks] )		[newUrl setObject:[NSNumber numberWithInt:[eoPage followLinks]] forKey:@"followlinks"];
                            if( [eoPage linkDepth] )		[newUrl setObject:[NSNumber numberWithInt:[eoPage linkDepth]] forKey:@"linkdepth"];
                            if( [[sitesInformationDictionary objectForKey:[eoSite siteName]] objectForKey:@"ipaddress"] )
                                [newUrl setObject:[[sitesInformationDictionary objectForKey:[eoSite siteName]] objectForKey:@"ipaddress"] forKey:@"ipaddress"];

                            [fetcherController fetchLocalUrl:newUrl];
                            [eoPage setFetchStatus: FETCH_STATUS_FETCHING];
                        }
                        else
                        {
                            NSLog(@"HooverController stageWorkLoop: popped site with no work: siteID=%@ currentStage=%d", siteidNumber,[currentStage currentStage]);
                        }
                    }
                    [eoEditingContext saveChanges];
                }
            }
            else
            {
                NSLog(@"HooverController stageWorkLoop: queue was empty while stage increased");
            }
            [innerPool release];
        }
        [currentStage setCurrentStage:[currentStage currentStage]+1];
        [eoEditingContext saveChanges];
        [stagePool release];
    }//while(1) 
}


- (void)retrievedUrl:(NSMutableDictionary *)url;
{
    NSLog(@"HooverController retrievedUrl:%@",url);
    [receivedUrlsQueue push:url];
}

- (void)runTheRetrievingThread;
{
    while(1)
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        NSMutableDictionary	*url = [receivedUrlsQueue pop];
        EOEditingContext	*eoEditingContext = [[[EOEditingContext alloc] initWithParentObjectStore:[EOObjectStoreCoordinator defaultCoordinator]] autorelease];

        Site *eoSite = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_SITE
                                                                                                                     qualifier:[EOQualifier qualifierWithQualifierFormat:@"siteID = %@",[url objectForKey:@"siteid"]]	
                                                                                                                 sortOrderings:nil]] lastObject];
        if( nil != eoSite )
        {
            NSMutableDictionary	*siteDictionary = [sitesInformationDictionary objectForKey:[eoSite siteName]];

            if( nil == siteDictionary )
            {
                siteDictionary = [NSMutableDictionary dictionary];
                [siteDictionary setObject:[NSNumber numberWithInt:1] forKey:@"timetowait"];
                [sitesInformationDictionary setObject:siteDictionary forKey:[eoSite siteName]];
            }

            
            if(! [[url objectForKey:@"status"] isEqual:@"invalid"] )		// possible stati : invalid,fetched,redirected
            {
                [siteDictionary setObject:[NSNumber numberWithInt:1] forKey:@"timetowait"];
                
                if( [[url objectForKey:@"path"] isEqual:ROBOTS_PATH] )		// if it's a robots.txt then remember the robots data and the ipaddress
                {
                    [eoSite setRobotsData:[url objectForKey:@"robotsdata"]];
                    [eoSite setRobotsDate:[url objectForKey:@"transferdate"]];
                    [siteDictionary setObject:[url objectForKey:@"ipaddress"] forKey:@"ipaddress"];
                    [allSitesDatedQueue push:[NSNumber numberWithInt:[eoSite siteID]]
                                    withDate:[[url objectForKey:@"transferdate"] addTimeInterval:REFETCH_FACTOR*[[url objectForKey:@"transfertime"] floatValue]]];
                }
                else
                {
                    Page *eoPage = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_PAGE
                                                                                                    qualifier:[EOQualifier qualifierWithQualifierFormat:@"pageID = %@",[url objectForKey:@"pageid"]]
                                                                           	        	sortOrderings:nil]] lastObject];
                    if( nil != eoPage )
                    {
                        NSTimeInterval	timetowait = [eoPage crawlTimeFactor]*[[url objectForKey:@"transfertime"] floatValue];

                        if( timetowait < [eoPage crawlTimeMinimum] )
                        {
                            timetowait = [eoPage crawlTimeMinimum];
                        }
                        else if( timetowait > [eoPage crawlTimeMaximum] )
                        {
                            timetowait = [eoPage crawlTimeMaximum];
                        }
                     
                        [eoPage setFetchStatus:FETCH_STATUS_FETCHED];
                        [allSitesDatedQueue push:[NSNumber numberWithInt:[eoSite siteID]] withDate:[[url objectForKey:@"transferdate"] addTimeInterval:timetowait]];
                    }
                    else
                    {
                        NSLog(@"HooverController runTheRetrievingThread: got Url for Site where the Url is no longer in the database : %@",[url description]);
                        [allSitesDatedQueue push:[NSNumber numberWithInt:[eoSite siteID]]
                                        withDate:[[url objectForKey:@"transferdate"] addTimeInterval:REFETCH_FACTOR*[[url objectForKey:@"transfertime"] floatValue]]];
                    }
                }
            }
            else // invalid status
            {
                NSTimeInterval timetowait = [[siteDictionary objectForKey:@"timetowait"] floatValue] * 2.0;

                if( [url objectForKey:@"pageid"] )
                {
                    Page *eoPage = [[eoEditingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:ENTITY_NAME_PAGE
                                                                                                                                 qualifier:[EOQualifier qualifierWithQualifierFormat:@"pageID = %@",[url objectForKey:@"pageid"]]
                                                                                                                             sortOrderings:nil]] lastObject];
                    if( nil != eoPage )
                    {
                        [eoPage setFetchStatus:FETCH_STATUS_TOFETCH];
                    }
                }
                
                if( timetowait < FAILEDFETCH_MINIMUM_TIMETOWAIT )
                {
                    timetowait = FAILEDFETCH_MINIMUM_TIMETOWAIT;
                }
                else if( timetowait > FAILEDFETCH_MAXIMUM_TIMETOWAIT )
                {
                    timetowait = FAILEDFETCH_MAXIMUM_TIMETOWAIT;
                }
                [allSitesDatedQueue push:[NSNumber numberWithInt:[eoSite siteID]] withDate:[NSDate dateWithTimeIntervalSinceNow:timetowait]];
            }
        }
        else
        {
            NSLog(@"HooverController runTheRetrievingThread: got Url for Site where the site is no longer in the database : %@",[url description]);
        }
        [eoEditingContext saveChanges];
        [pool release];
    }
}


- (void)save;
{
    NSAutoreleasePool 	*pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"HooverController: -save");
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
    [pool release];
}

@end




