//
//  MMDragonEar.h
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDragonEarDelegate.h"

@interface MMDragonEar : NSObject

+ (instancetype) sharedInstance;

-(instancetype) init NS_UNAVAILABLE;

@property (nonatomic, weak) id<MMDragonEarDelegate> delgate;
@property (nonatomic, assign, getter=isListening) BOOL listening;

@end
