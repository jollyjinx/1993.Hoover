// Site.h
// 
// Created on Sat Jan 27 16:10:33 CET 2001 by NeXT EOModeler Version 305

#import <EOControl/EOControl.h>

@class Page;

@interface Site : NSObject <NSCoding>
{
    int port;
    int siteID;
    NSString *robotsData;
    NSCalendarDate *robotsDate;
    NSString *siteName;
    NSMutableArray *pages;
}

- (void)setPort:(int) value;
- (int) port;

- (void)setSiteID:(int) value;
- (int) siteID;

- (void)setRobotsData:(NSString *)value;
- (NSString *)robotsData;

- (void)setRobotsDate:(NSCalendarDate *)value;
- (NSCalendarDate *)robotsDate;

- (void)setSiteName:(NSString *)value;
- (NSString *)siteName;

- (NSArray *)pages;
- (void)addToPages:(Page *)object;
- (void)removeFromPages:(Page *)object;

@end
