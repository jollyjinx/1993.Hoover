#import <Foundation/Foundation.h>

@interface LockTest : NSObject
- (void)doit:(NSConditionLock *)aConditionLock;
@end

@implementation LockTest

- (void)doit:(NSConditionLock *)aConditionLock
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	while(1)
	{
		//NSLog(@"Subthread: Locking when condition == 1 ...");

		if( YES == [aConditionLock lockWhenCondition:1 beforeDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval).1]] )
		{
			NSLog(@"Subthread: got Condition in time - locked.");
			[aConditionLock unlockWithCondition:0];
		}
		else
			NSLog(@"Subthread: did not get Condition in time - not locked.");
	}
	[pool release];
}

@end

int main (int argc, const char *argv[])
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	LockTest			*lockTest = [[LockTest alloc] init];
	NSConditionLock 	*aConditionLock = [[NSConditionLock alloc] initWithCondition:0];
	int i;
	
	[NSThread detachNewThreadSelector:@selector(doit:)
        	            	 toTarget:lockTest
            	    	   withObject:aConditionLock];
	[lockTest release];
	[aConditionLock release];
	while(1)
	{
		NSLog(@"MainThread: Sleeping...");
		sleep(1);
		NSLog(@"MainThread: Waking...");
		[aConditionLock lock];
		[aConditionLock unlockWithCondition:1];
	}
	[pool release];
}
