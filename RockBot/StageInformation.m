// StageInformation.m
//
// Created on Sat Jan 27 12:21:35 CET 2001 by NeXT EOModeler Version 305

#import "StageInformation.h"


@implementation StageInformation

// EditingContext-based archiving support.  Useful for WebObjects
// applications that store state in the page or in cookies.

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[EOEditingContext encodeObject:self withCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	return [EOEditingContext initObject:self withCoder:aDecoder];
}

- (void)setStageIntervall:(int) value
{
    [self willChange];
    stageIntervall = value;
}
- (int) stageIntervall { return stageIntervall; }

- (void)setCurrentStage:(int) value
{
    [self willChange];
    currentStage = value;
}
- (int) currentStage { return currentStage; }

- (void)setStageInformationId:(int) value
{
    [self willChange];
    stageInformationId = value;
}
- (int) stageInformationId { return stageInformationId; }


- (void)dealloc
{
    
    [super dealloc];
}

@end
