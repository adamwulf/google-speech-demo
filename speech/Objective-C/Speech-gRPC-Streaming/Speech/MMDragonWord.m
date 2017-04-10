//
//  MMDragonWord.m
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonWord.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation MMDragonWord

-(instancetype) initWithWord:(NSString*)word{
    if(self = [super init]){
        _word = word;
        _nextWords = [NSMutableArray array];

        _start = CGFLOAT_MAX;
        _stop = CGFLOAT_MAX;
        _micDelay = 0;
        _flightDelay = 0;
    }
    return self;
}

-(void)increment{
    _count += 1;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"[MMDragonWord %@ %ld]", _word, (long)_count];
}

@end
