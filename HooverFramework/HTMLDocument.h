/* HTMLDocument.h created by jolly on Tue 18-Nov-1997 */

#import <Foundation/Foundation.h>
#import "Categories.h"

@interface HTMLDocument : NSObject
{
    NSString		*documentContent;
    NSMutableArray	*htmlArray;
}

+ (HTMLDocument *)documentWithData:(NSData *)htmlData;
+ (NSMutableString *)decodeHTMLTags:(NSString *)stringToDecode;

- (id)initWithData:(NSData *)htmlData encoding:(NSStringEncoding)encoding;
- (id)initWithData:(NSData *)htmlData;


- (NSMutableArray *)htmlArray;
- (NSMutableArray *)urlArray;

- (NSMutableString *)textRepresentation;

@end
