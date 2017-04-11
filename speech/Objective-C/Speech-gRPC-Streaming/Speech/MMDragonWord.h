//
//  MMDragonWord.h
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMDragonWord : NSObject<NSCopying>

-(instancetype) init NS_UNAVAILABLE;
-(instancetype) initWithWord:(NSString*)word;

@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval stop;
@property (nonatomic, assign) NSTimeInterval micDelay;
@property (nonatomic, assign) NSTimeInterval flightDelay;
@property (nonatomic, strong) NSString* word;

@property (nonatomic, readonly) NSMutableArray* nextWords;

@property (nonatomic, readonly) NSInteger count;

-(void) increment;
-(NSInteger) depth;

@end
