/* Worker.h created by jolly on Wed 14-May-1997 */

#import <Foundation/Foundation.h>

@interface Worker : NSObject
+ (Worker *)worker;

- (void)retrieveUrl:(NSMutableDictionary *)url;

@end

