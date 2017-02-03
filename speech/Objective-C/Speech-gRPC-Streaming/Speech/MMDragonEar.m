//
//  MMDragonEar.m
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMDragonEar.h"
#import <AVFoundation/AVFoundation.h>

#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "google/cloud/speech/v1beta1/CloudSpeech.pbrpc.h"
#import "MMDragonPhrase.h"

#define SAMPLE_RATE 16000.0f

@interface MMDragonEar () <AudioControllerDelegate>

@property (nonatomic, strong) NSMutableData *audioData;

@end

@implementation MMDragonEar{
    NSTimeInterval _mostRecentDataSent;
    BOOL _shouldKillStream;
    MMDragonPhrase *_inFlightPhrase;
}

+ (instancetype) sharedInstance {
    static MMDragonEar *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
        [AudioController sharedInstance].delegate = instance;
    }
    return instance;
}

-(void) setListening:(BOOL)listening{
    _listening = listening;
    
    if([self isListening]){
        [self recordAudio];
    }else{
        [self stopAudio];
    }
}

- (void)recordAudio {
    [[self delgate] willBeginProcessingAudio:self];

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    
    _audioData = [[NSMutableData alloc] init];
    [[AudioController sharedInstance] prepareWithSampleRate:SAMPLE_RATE];
    [[SpeechRecognitionService sharedInstance] setSampleRate:SAMPLE_RATE];
    [[AudioController sharedInstance] start];
}

- (void)stopAudio {
    [[AudioController sharedInstance] stop];
    [[SpeechRecognitionService sharedInstance] stopStreaming];
    
    [[self delgate] didEndProcessingAudio:self];
}

- (void) processSampleData:(NSData *)data withMicDelay:(NSTimeInterval)micDelay
{
    [self.audioData appendData:data];
    NSInteger frameCount = [data length] / 2;
    int16_t *samples = (int16_t *) [data bytes];
    int64_t sum = 0;
    for (int i = 0; i < frameCount; i++) {
        sum += abs(samples[i]);
    }
    
//    NSLog(@"audio %d %d", (int) frameCount, (int) (sum * 1.0 / frameCount));
    
    // We recommend sending samples in 100ms chunks
    int chunk_size = 0.1 /* seconds/chunk */ * SAMPLE_RATE * 2 /* bytes/sample */ ; /* bytes/chunk */
    
    if ([self.audioData length] > chunk_size) {
        _mostRecentDataSent = [NSDate timeIntervalSinceReferenceDate];
        [[SpeechRecognitionService sharedInstance] streamAudioData:self.audioData
                                                    withCompletion:^(BOOL didInitializeStream, StreamingRecognizeResponse *response, NSError *error) {
                                                        NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
                                                        
                                                        NSTimeInterval flightDelay = end - _mostRecentDataSent;
                                                        
                                                        if (error) {
                                                            NSLog(@"ERROR: %@", error);
                                                            [[self delgate] dragonEar:self errorProcessingAudio:error];
                                                            [self stopAudio];
                                                        } else if (response) {
                                                            
                                                            if(!_inFlightPhrase){
                                                                _inFlightPhrase = [[MMDragonPhrase alloc] init];
                                                            }
                                                            
                                                            [_inFlightPhrase updateWithStreamingResponse:response withMicDelay:micDelay andFlightDelay:flightDelay atTime:[NSDate timeIntervalSinceReferenceDate]];
                                                            
                                                            [[self delgate] dragonEar:self didHearResponse:_inFlightPhrase];

                                                            for (StreamingRecognitionResult *result in response.resultsArray) {
                                                                if([result isFinal]){
                                                                    NSLog(@"Resetting the stream.");
                                                                    [self triggerKillTimer];
                                                                    break;
                                                                }
                                                            }
                                                            
                                                            if([_inFlightPhrase isComplete]){
                                                                _inFlightPhrase = nil;
                                                            }
                                                            
                                                        }else if(didInitializeStream){
                                                            NSLog(@"didInitializeStream");
                                                            [self scheduleKillTimer];
                                                        }
                                                    }
         ];
        self.audioData = [[NSMutableData alloc] init];
    }
}

-(void) scheduleKillTimer{
    NSLog(@"scheduleKillTimer");
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(triggerKillTimer) object:nil];
        [self performSelector:@selector(triggerKillTimer) withObject:nil afterDelay:50];
    });
}

-(void) triggerKillTimer{
    NSLog(@"triggerKillTimer");
    
    [[SpeechRecognitionService sharedInstance] stopStreaming];
}

@end
