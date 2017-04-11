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

@interface MMDragonGraph ()

@property (nonatomic, strong) NSMutableArray* startingWords;

@end

@implementation MMDragonGraph{
    NSMutableArray<MMDragonWord*>* wordsWithoutEnd;
}

-(instancetype) initWithResponses:(NSArray<NSDictionary*>*)responses{
    if(self = [super init]){
        
        wordsWithoutEnd = [NSMutableArray array];
        _startingWords = [NSMutableArray array];
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
                    [conciseResponses addObject:mutMoment];
                }else{
                    foundFinal = YES;
                }
            }else{
                [conciseResponses addObject:mutMoment];
            }
        }
        
        if(foundFinal){
            NSLog(@"found final");
        }
        NSLog(@"========================================");
        NSLog(@"build graph for: %@", conciseResponses);
        
        
        for (NSDictionary* moment in conciseResponses) {
            [self addMomentToGraph:moment];
        }
        
        
        
        NSLog(@"========================================");
        NSLog(@"all words:");
        
        NSMutableArray* allWords = [[self startingWords] mutableCopy];
        while ([allWords count]) {
            MMDragonWord* word = [allWords firstObject];
            
            NSLog(@"%@  %.2f %.2f", word, word.start, word.stop);
            
            [allWords addObjectsFromArray:[word nextWords]];
            [allWords removeObjectAtIndex:0];
        }
        
    }
    
    return self;
}

-(void) addMomentToGraph:(NSDictionary*)moment{
    NSArray* words = [moment[@"response"] componentsSeparatedByString:@" "];
    
    for (MMDragonWord* word in wordsWithoutEnd) {
        word.stop = [moment[@"timestamp"] doubleValue];
    }
    [wordsWithoutEnd removeAllObjects];
    
    if(![words count]){
        return;
    }
    
    
    MMDragonWord* startingWord = [[self startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
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
        [_startingWords addObject:startingWord];
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

-(NSArray<MMDragonWord*>*) bestPhrase{
    
    MMDragonWord*(^reduceToBestWord)(MMDragonWord*, NSUInteger, MMDragonWord*) = ^MMDragonWord*(MMDragonWord* obj, NSUInteger index, MMDragonWord* accum) {
        if(!accum){
            return obj;
        }else if([[obj nextWords] count] > [[accum nextWords] count]){
            return obj;
        }
        return accum;
    };
    
    NSMutableArray<MMDragonWord*>* output = [NSMutableArray array];

    if([_startingWords count]){
        MMDragonWord* bestWord = [_startingWords reduce:reduceToBestWord];
        [output addObject:bestWord];
        
        while ([[[output lastObject] nextWords] count]) {
            bestWord = [[[output lastObject] nextWords] reduce:reduceToBestWord];
            [output addObject:bestWord];
        }
    }
    
    return output;
}

@end
