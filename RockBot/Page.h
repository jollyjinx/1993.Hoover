// Page.h
// 
// Created on Sat Jan 27 17:09:20 CET 2001 by NeXT EOModeler Version 305

#import <EOControl/EOControl.h>

@class Site;

@interface Page : NSObject <NSCoding>
{
    int pageID;
    int siteID;
    int shopID;
    int currentStage;
    int fetchStatus;
    int linkDepth;
    int followLinks;
    double crawlTimeFactor;
    double crawlTimeMaximum;
    double crawlTimeMinimum;
    NSString *path;
    NSString *md5Page;
    NSCalendarDate *lastDownloaded;
    NSCalendarDate *dateInserted;
    id shop;
    Site * site;
}

- (void)setPageID:(int) value;
- (int) pageID;

- (void)setSiteID:(int) value;
- (int) siteID;

- (void)setShopID:(int) value;
- (int) shopID;

- (void)setCurrentStage:(int) value;
- (int) currentStage;

- (void)setFetchStatus:(int) value;
- (int) fetchStatus;

- (void)setLinkDepth:(int) value;
- (int) linkDepth;

- (void)setFollowLinks:(int) value;
- (int) followLinks;

- (void)setCrawlTimeFactor:(double) value;
- (double) crawlTimeFactor;

- (void)setCrawlTimeMaximum:(double) value;
- (double) crawlTimeMaximum;

- (void)setCrawlTimeMinimum:(double) value;
- (double) crawlTimeMinimum;

- (void)setPath:(NSString *)value;
- (NSString *)path;

- (void)setMd5Page:(NSString *)value;
- (NSString *)md5Page;

- (void)setLastDownloaded:(NSCalendarDate *)value;
- (NSCalendarDate *)lastDownloaded;

- (void)setDateInserted:(NSCalendarDate *)value;
- (NSCalendarDate *)dateInserted;

- (void)setShop:(id)value;
- (id)shop;

- (void)setSite:(Site *)value;
- (Site *)site;

@end
