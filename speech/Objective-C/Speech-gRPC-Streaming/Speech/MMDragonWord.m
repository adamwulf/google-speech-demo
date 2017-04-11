//
//  MMDragonWord.m
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonWord.h"
#import "NSArray+MapReduce.h"
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

-(void) setStart:(NSTimeInterval)start{
    _start = start;
    if(self.start && self.stop && self.start > self.stop){
        NSLog(@"gotcha");
    }
}

-(void) setStop:(NSTimeInterval)stop{
    _stop = stop;
    if(self.start && self.stop && self.start > self.stop){
        NSLog(@"gotcha");
    }
}

-(MMDragonWord*) nextWordFor:(NSString *)stringWord{
    if(!stringWord){
        return nil;
    }
    
    for (MMDragonWord* child in [self nextWords]) {
        if([[child word] isEqualToString:stringWord]){
            return child;
        }
    }
    return nil;
}

-(void)increment{
    _count += 1;
}

-(NSInteger) depth{
    return 1 + [[self nextWords] reduceToInteger:^NSInteger(MMDragonWord* obj, NSUInteger index, NSInteger accum) {
        return MAX([obj depth], accum);
    }];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"[MMDragonWord %@ %ld]", _word, (long)_count];
}

#pragma mark - NSCopying


- (id)copyWithZone:(NSZone *)zone {
    MMDragonWord *copiedWord = [[[self class] allocWithZone:zone] initWithWord:[self word]];
    
    copiedWord.start = self.start;
    copiedWord.stop = self.stop;
    copiedWord.micDelay = self.micDelay;
    copiedWord.flightDelay = self.flightDelay;
    
    [copiedWord.nextWords addObjectsFromArray:[[NSArray alloc] initWithArray:[self nextWords] copyItems:YES]];
    
    for (NSInteger i=0; i<[self count]; i++) {
        [copiedWord increment];
    }

    return copiedWord;
}

-(NSUInteger) hash{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + self.start;
    result = prime * result + self.stop;
    result = prime * result + self.micDelay;
    result = prime * result + self.flightDelay;
    result = prime * result + [self.word hash];
    return result;
}

@end
