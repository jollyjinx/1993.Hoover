
#import <Foundation/Foundation.h>


@interface MyWorld:NSObject
{
	NSString *myHelloString;
}

- (id)init;
- (void)sayHelloToEverybody;

@end

@implementation MyWorld:NSObject
{
	NSString *myHelloString;
}

- (id)init
{
	[super init];
	
	myHelloString = @"Blub\n";
	return self;
}


- (void)sayHelloToEverybody
{
	NSLog(myHelloString);;
}


@end

int main (int argc, const char *argv[])
{
	MyWorld *myWorld;
	
	myWorld = [[MyWorld alloc] init];
	
	[myWorld sayHelloToEverybody];
}
