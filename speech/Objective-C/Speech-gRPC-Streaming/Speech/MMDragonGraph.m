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
        CGFloat finalTimestamp = CGFLOAT_MAX;
        
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
                    if([moment[@"response"] count]){
                        NSArray<NSDictionary*>* response = moment[@"response"][0];
                        if([response count]){
                            mutMoment[@"response"] = response[0][@"text"];
                            [conciseResponses addObject:mutMoment];
                        }
                    }
                    foundFinal = YES;
                }
            }else{
                [conciseResponses addObject:mutMoment];
            }
            
            if(moment[@"timestamp"]){
                finalTimestamp = [moment[@"timestamp"] doubleValue];
            }
        }
        
        for (NSDictionary* moment in conciseResponses) {
            if(moment == [conciseResponses lastObject]){
                NSLog(@"break");
            }
            [self addMomentToGraph:moment];
        }
        
        for (MMDragonWord* word in wordsWithoutEnd) {
            word.stop = finalTimestamp;
        }
        [wordsWithoutEnd removeAllObjects];
        

        // make sure timings of words don't overlap
        NSMutableArray* wordsToValidate = [NSMutableArray arrayWithArray:[self startingWords]];
        
        while([wordsToValidate count]){
            MMDragonWord* firstWord = [wordsToValidate firstObject];
            for (MMDragonWord* secondWord in firstWord.nextWords) {
                if([firstWord stop] >= [secondWord start]){
                    NSTimeInterval mid = ([firstWord stop] + [secondWord start]) / 2.0;
                    [firstWord setStop:mid];
                    [secondWord setStart:mid];
                }
            }
            
            [wordsToValidate removeObjectAtIndex:0];
            [wordsToValidate addObjectsFromArray:[firstWord nextWords]];
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
    
    if(![words count]){
        [wordsWithoutEnd removeAllObjects];
        return;
    }
    
    CGFloat lastOfLastWordWithoutEnd = [[wordsWithoutEnd lastObject] start];
    [wordsWithoutEnd removeAllObjects];
    
    MMDragonWord* startingWord = [[self startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        if(!accum && [[obj word] isEqualToString:words[0]]){
            return obj;
        }
        
        return accum;
    }];
    
    MMDragonWord*(^createWordFor)(NSString*, MMDragonWord*, MMDragonWord*) = ^(NSString* text, MMDragonWord* previousWord, MMDragonWord* previousFork){
        // check if we've see this word before:
        __block MMDragonWord*(^findPossibleWordFrom)(MMDragonWord*);
        MMDragonWord* (^__block __weak weakFindPossibleWordFrom)(MMDragonWord*);
        weakFindPossibleWordFrom = findPossibleWordFrom = ^MMDragonWord*(MMDragonWord* previousFork){
            if([[previousFork word] isEqualToString:text]){
                // ensure that the previous word doesn't appear
                // in our found word's future
                // TODO: find a test case for this
                NSMutableArray* wordsToCheck = [NSMutableArray arrayWithObject:previousFork];
                while([wordsToCheck count]){
                    MMDragonWord* wordToCheck = [wordsToCheck firstObject];
                    if([wordToCheck isEqual:previousWord]){
                        return nil;
                    }
                    [wordsToCheck removeObjectAtIndex:0];
                    [wordsToCheck addObjectsFromArray:[wordToCheck nextWords]];
                }
                
                return previousFork;
            }
            for (MMDragonWord* childWord in [previousFork nextWords]) {
                MMDragonWord* foundInChildren = weakFindPossibleWordFrom(childWord);
                if(foundInChildren){
                    return foundInChildren;
                }
            }
            return nil;
        };
        
        if(previousFork){
            NSArray* previousToCheck = [_startingWords containsObject:previousFork] ? _startingWords : @[previousFork];
            for (MMDragonWord* previousForkStart in previousToCheck) {
                MMDragonWord* possiblySeen = findPossibleWordFrom(previousForkStart);
                
                if(possiblySeen){
                    if([possiblySeen stop] < [previousWord start]){
                        // don't allow us to loop backward in time.
                        // if we have a stop timestamp, then
                        // this definitely isn't our word.
                    }else{
                        return possiblySeen;
                    }
                }
            }
        }
        
        // if not, build a new word
        MMDragonWord* word = [[MMDragonWord alloc] initWithWord:text];
        word.start = [moment[@"timestamp"] doubleValue];
        
        if([previousWord.nextWords count]){
            word.start = [[previousWord nextWords] reduceToFloat:^CGFloat(MMDragonWord* obj, NSUInteger index, CGFloat accum) {
                return accum ? MIN([obj start], accum) : [obj start];
            }];
        }else if(lastOfLastWordWithoutEnd > 0){
            word.start = lastOfLastWordWithoutEnd;
        }
        
        word.micDelay = [moment[@"micDelay"] doubleValue];
        word.flightDelay = [moment[@"flightDelay"] doubleValue];
        [wordsWithoutEnd addObject:word];
        return word;
    };
    
    
    if(!startingWord){
        startingWord = createWordFor(words[0], nil, nil);
        [_startingWords addObject:startingWord];
    }else{
        [startingWord increment];
    }
    
    MMDragonWord* previousWord = startingWord;
    MMDragonWord* latestFork = startingWord;
    
    for (NSInteger i=1; i<[words count]; i++) {
        MMDragonWord* nextWord = [previousWord.nextWords reduce:^id(id obj, NSUInteger index, id accum) {
            if(!accum && [[obj word] isEqualToString:words[i]]){
                return obj;
            }
            
            return accum;
        }];
        
        if(!nextWord){
            nextWord = createWordFor(words[i], previousWord, latestFork);
            [[previousWord nextWords] addObject:nextWord];
        }else{
            if(!latestFork || [[nextWord nextWords] count] > 1){
                // make sure to use only forking words
                // as the last fork.
                latestFork = nextWord;
            }
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
