//
//  MMDragonPhrase.m
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonPhrase.h"
#import "SpeechRecognitionService.h"
#import "NSArray+MapReduce.h"

@implementation MMDragonPhrase{
    NSMutableArray* _phraseEvents;
    NSTimeInterval _phraseStart;
}

-(instancetype) init{
    if(self = [super init]){
        _phraseEvents = [NSMutableArray array];
        _identifier = [[NSUUID UUID] UUIDString];
        _phraseStart = [NSDate timeIntervalSinceReferenceDate];
    }
    
    return self;
}

-(NSArray<NSArray<NSDictionary*>*>*) responseAsDictionary:(StreamingRecognizeResponse*)response{
    return [response.resultsArray map:^id(StreamingRecognitionResult *obj, NSUInteger index) {
        return [obj.alternativesArray map:^id(SpeechRecognitionAlternative *obj, NSUInteger index) {
            return @{ @"text" : obj.transcript, @"confidence" : @(obj.confidence) };
        }];
    }];
}

-(NSArray<NSDictionary*>*)debugEventData{
    return [_phraseEvents map:^id(id obj, NSUInteger index) {
        if(obj[@"response"]){
            
            NSMutableDictionary* mut = [obj mutableCopy];
            
            mut[@"response"] = [self responseAsDictionary:mut[@"response"]];
            
            return mut;
        }
        
        return obj;
    }];
}

-(void) updateWithStreamingResponse:(StreamingRecognizeResponse*)response withMicDelay:(NSTimeInterval)micDelay atTime:(NSTimeInterval)timestampOfResponse{
    NSTimeInterval _mostRecentDataSent = [NSDate timeIntervalSinceReferenceDate];
    
    for (NSDictionary* event in [_phraseEvents reverseObjectEnumerator]) {
        if(event[@"timeOfSentData"]){
            _mostRecentDataSent = [event[@"timeOfSentData"] doubleValue];
            break;
        }
    }
    
    NSTimeInterval flightDelay = timestampOfResponse - _mostRecentDataSent;
    
    if([self isComplete]){
        @throw [NSException exceptionWithName:@"MMDragonPhraseExceptoin" reason:@"cannot update complete phrase" userInfo:nil];
    }
    
    [_phraseEvents addObject:@{
                               @"response" : response,
                               @"micDelay" : @(micDelay),
                               @"flightDelay" : @(flightDelay),
                               @"timestamp" : @(timestampOfResponse)
                               }];
    
    for (StreamingRecognitionResult* result in response.resultsArray) {
        if(result.isFinal){
            _complete = YES;
            break;
        }
    }
}

-(void) updateWithSentDataTimestamp:(NSTimeInterval)timestampOfSentData{
    [_phraseEvents addObject:@{
                               @"timestamp" : @(timestampOfSentData)
                               }];
}

-(StreamingRecognitionResult*) bestResult{
    for (NSDictionary* event in [_phraseEvents reverseObjectEnumerator]) {
        if(event[@"response"]){
            StreamingRecognizeResponse* recentResponse = event[@"response"];
            
            return [[recentResponse resultsArray] firstObject];
        }
    }

    return nil;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding{
    return YES;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        _phraseEvents = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"phraseEvents"];
        _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
        _phraseStart = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"phraseStart"] doubleValue];
    }
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_phraseEvents forKey:@"phraseEvents"];
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:@(_phraseStart) forKey:@"phraseStart"];
}

@end
