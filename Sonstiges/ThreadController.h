/* ThreadController.h created by jolly on Mon 10-Mar-1997 */

#import <Foundation/Foundation.h>

@interface ThreadController : NSObject
{
    NSString		*connectionName;
    NSConnection	*rootConnection;
}

- initWithRootObject:(id)root;
- rootObject;


@end
