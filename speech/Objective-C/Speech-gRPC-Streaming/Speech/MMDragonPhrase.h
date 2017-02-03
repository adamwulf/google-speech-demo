//
//  MMDragonPhrase.h
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StreamingRecognizeResponse, StreamingRecognitionResult;

@interface MMDragonPhrase : NSObject<NSSecureCoding>

-(void) updateWithStreamingResponse:(StreamingRecognizeResponse*)response withMicDelay:(NSTimeInterval)micDelay andFlightDelay:(NSTimeInterval)flightDelay;

@property (nonatomic, readonly, getter=isComplete) BOOL complete;
@property (nonatomic, readonly) NSString *identifier;

@property (nonatomic, readonly) StreamingRecognitionResult* bestResult;

@end
