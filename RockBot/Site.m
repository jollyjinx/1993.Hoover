// Site.m
//
// Created on Sat Jan 27 16:10:33 CET 2001 by NeXT EOModeler Version 305

#import "Site.h"

#import "Page.h"

@implementation Site

// EditingContext-based archiving support.  Useful for WebObjects
// applications that store state in the page or in cookies.

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[EOEditingContext encodeObject:self withCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	return [EOEditingContext initObject:self withCoder:aDecoder];
}

- (void)setPort:(int) value
{
    [self willChange];
    port = value;
}
- (int) port { return port; }

- (void)setSiteID:(int) value
{
    [self willChange];
    siteID = value;
}
- (int) siteID { return siteID; }

- (void)setRobotsData:(NSString *)value
{
    [self willChange];
    [robotsData autorelease];
    robotsData = [value retain];
}
- (NSString *)robotsData { return robotsData; }

- (void)setRobotsDate:(NSCalendarDate *)value
{
    [self willChange];
    [robotsDate autorelease];
    robotsDate = [value retain];
}
- (NSCalendarDate *)robotsDate { return robotsDate; }

- (void)setSiteName:(NSString *)value
{
    [self willChange];
    [siteName autorelease];
    siteName = [value retain];
}
- (NSString *)siteName { return siteName; }

- (void)addToPages:(Page *)object
{
    // a to-many relationship
    [self willChange];
    [pages addObject:object];
}
- (void)removeFromPages:(Page *)object
{
    // a to-many relationship
    [self willChange];
    [pages removeObject:object];
}
- (NSArray *)pages { return pages; }


- (void)dealloc
{
    [robotsData release];
    [robotsDate release];
    [siteName release];
    [pages release];
    
    [super dealloc];
}

@end
