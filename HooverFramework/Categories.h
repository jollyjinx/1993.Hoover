/* Categories.h created by jolly on Wed 17-Dec-1997 */

#import <Foundation/Foundation.h>

@interface NSString(stringWithDataCreation)
+(NSString *) stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
@end


@interface NSFileHandle(fileHandleWithFileDescriptorCreation)
+(NSFileHandle *)fileHandleWithFileDescriptor:(int)fd closeOnDealloc:(BOOL)flag;
@end
