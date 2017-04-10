//
//  MMDragonGraph.m
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonGraph.h"
#import "MMDragonWord.h"
#import "NSArray+MapReduce.h"

@implementation MMDragonGraph{
    NSMutableArray* startingWords;
    NSMutableArray* wordsWithoutEnd;
}

-(instancetype) initWithResponses:(NSArray<NSDictionary*>*)responses{
    if(self = [super init]){
        
        wordsWithoutEnd = [NSMutableArray array];
        startingWords = [NSMutableArray array];
        NSMutableArray* conciseResponses = [NSMutableArray array];
        
        BOOL foundFinal = NO;
        
        for (NSDictionary* moment in responses) {
            NSMutableDictionary* mutMoment = [moment mutableCopy];
            if(moment[@"response"]){
                if(![moment[@"isFinal"] boolValue]){
                    mutMoment[@"response"] = [mutMoment[@"response"] reduce:^NSString*(NSArray* obj, NSUInteger index, id accum) {
                        NSString* str = [obj reduce:^id(id obj, NSUInteger index, id accum) {
                            return obj[@"text"];
                        }];
                        
                        if(accum){
                            return [accum stringByAppendingString:str];
                        }

                        return str;
                    }];
                }else{
                    foundFinal = YES;
                }
            }
            [conciseResponses addObject:mutMoment];
        }
        
        if(foundFinal){
            NSLog(@"found final");
        }
        NSLog(@"========================================");
        NSLog(@"build graph for: %@", conciseResponses);
        
        
        for (NSDictionary* moment in conciseResponses) {
            [self addMomentToGraph:moment];
        }
    }
    
    return self;
}

-(void) addMomentToGraph:(NSDictionary*)moment{
    NSArray* words = [moment[@"response"] componentsSeparatedByString:@" "];
    
    if(![words count]){
        for (MMDragonWord* word in wordsWithoutEnd) {
            word.stop = [moment[@"timestamp"] doubleValue];
        }
        [wordsWithoutEnd removeAllObjects];
        return;
    }
    
    MMDragonWord* startingWord = [startingWords reduce:^id(id obj, NSUInteger index, id accum) {
        if(!accum && [[obj word] isEqualToString:words[0]]){
            return obj;
        }
        
        return accum;
    }];
    
    
    
    MMDragonWord*(^createWordFor)(NSString* word) = ^(NSString* text){
        MMDragonWord* word = [[MMDragonWord alloc] initWithWord:text];
        word.start = [moment[@"timestamp"] doubleValue];
        word.micDelay = [moment[@"micDelay"] doubleValue];
        word.flightDelay = [moment[@"flightDelay"] doubleValue];
        [wordsWithoutEnd addObject:word];
        return word;
    };
    
    
    if(!startingWord){
        startingWord = createWordFor(words[0]);
        [startingWords addObject:startingWord];
    }else{
        [startingWord increment];
    }
    
    MMDragonWord* previousWord = startingWord;
    
    for (NSInteger i=1; i<[words count]; i++) {
        MMDragonWord* nextWord = [previousWord.nextWords reduce:^id(id obj, NSUInteger index, id accum) {
            if(!accum && [[obj word] isEqualToString:words[i]]){
                return obj;
            }
            
            return accum;
        }];
        
        if(!nextWord){
            nextWord = createWordFor(words[i]);
            [[previousWord nextWords] addObject:nextWord];
        }else{
            [nextWord increment];
        }
        
        previousWord = nextWord;
    }
    
}

@end
