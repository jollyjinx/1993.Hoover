/* Categories.m created by jolly on Wed 17-Dec-1997 */

#import <HooverFramework/Categories.h> 

@implementation NSString(stringWithDataCreation)

+(NSString *) stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
{
    return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}

@end



@implementation NSFileHandle(fileHandleWithFileDescriptorCreation)

+(NSFileHandle *)fileHandleWithFileDescriptor:(int)fd closeOnDealloc:(BOOL)flag;
{
    return [[[self alloc] initWithFileDescriptor:fd closeOnDealloc:flag] autorelease];
}

@end
