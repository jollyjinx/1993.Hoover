// StageInformation.h
// 
// Created on Sat Jan 27 12:21:35 CET 2001 by NeXT EOModeler Version 305

#import <EOControl/EOControl.h>


@interface StageInformation : NSObject <NSCoding>
{
    int stageIntervall;
    int currentStage;
    int stageInformationId;
}

- (void)setStageIntervall:(int) value;
- (int) stageIntervall;

- (void)setCurrentStage:(int) value;
- (int) currentStage;

- (void)setStageInformationId:(int) value;
- (int) stageInformationId;

@end
