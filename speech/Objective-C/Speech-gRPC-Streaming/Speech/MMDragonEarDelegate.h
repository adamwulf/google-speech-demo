//
//  MMDragonEarDelegate.h
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMDragonEar, MMDragonPhrase;

@protocol MMDragonEarDelegate <NSObject>

-(void) willBeginProcessingAudio:(MMDragonEar*)dragonEar;

-(void) didEndProcessingAudio:(MMDragonEar*)dragonEar;

-(void) dragonEar:(MMDragonEar*)dragonEar errorProcessingAudio:(NSError*)error;

-(void) dragonEar:(MMDragonEar*)dragonEar didHearResponse:(MMDragonPhrase*)response;

@end
