//
//  MMDragonPhrase.m
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonPhrase.h"
#import "SpeechRecognitionService.h"

@implementation MMDragonPhrase{
    NSMutableArray* _allResponses;
    NSMutableArray* _allMicDelays;
    NSMutableArray* _allFlightDelays;
    NSMutableArray* _allResponseTimes;
    NSTimeInterval _phraseStart;
}

-(instancetype) init{
    if(self = [super init]){
        _allResponses = [NSMutableArray array];
        _allMicDelays = [NSMutableArray array];
        _allFlightDelays = [NSMutableArray array];
        _allResponseTimes = [NSMutableArray array];
        _identifier = [[NSUUID UUID] UUIDString];
        _phraseStart = [NSDate timeIntervalSinceReferenceDate];
    }
    
    return self;
}

-(void) updateWithStreamingResponse:(StreamingRecognizeResponse*)response withMicDelay:(NSTimeInterval)micDelay andFlightDelay:(NSTimeInterval)flightDelay atTime:(NSTimeInterval)timeOfResponse{
    [_allResponses addObject:response];
    [_allMicDelays addObject:@(micDelay)];
    [_allFlightDelays addObject:@(flightDelay)];
    [_allResponseTimes addObject:@(timeOfResponse)];
    
    for (StreamingRecognitionResult* result in response.resultsArray) {
        if(result.isFinal){
            _complete = YES;
            break;
        }
    }
}

-(StreamingRecognitionResult*) bestResult{
    StreamingRecognizeResponse* recentResponse = [_allResponses lastObject];
    
    return [[recentResponse resultsArray] firstObject];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding{
    return YES;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        _allResponses = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"allResponses"];
        _allMicDelays = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"allMicDelays"];
        _allFlightDelays = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"allFlightDelays"];
        _allResponseTimes = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"allResponseTimes"];
        _identifier = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
        _phraseStart = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"phraseStart"] doubleValue];
    }
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_allResponses forKey:@"allResponses"];
    [aCoder encodeObject:_allMicDelays forKey:@"allMicDelays"];
    [aCoder encodeObject:_allFlightDelays forKey:@"allFlightDelays"];
    [aCoder encodeObject:_allResponseTimes forKey:@"allResponseTimes"];
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:@(_phraseStart) forKey:@"phraseStart"];
}

@end
