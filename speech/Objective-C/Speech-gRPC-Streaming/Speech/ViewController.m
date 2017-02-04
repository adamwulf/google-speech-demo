//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "AudioController.h"
#import "SpeechRecognitionService.h"
#import "google/cloud/speech/v1beta1/CloudSpeech.pbrpc.h"
#import "MMDragonEar.h"
#import "MMDragonPhrase.h"
#import "MMDragonEarDelegate.h"
#import "MMPhraseDebugView.h"

#define SAMPLE_RATE 16000.0f

@interface ViewController () <MMDragonEarDelegate>
@property (nonatomic, strong) MMPhraseDebugView *debugView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableData *audioData;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
    _debugView = [[MMPhraseDebugView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    [_scrollView addSubview:_debugView];
    
    [[MMDragonEar sharedInstance] setDelgate:self];
}

- (IBAction)recordAudio:(id)sender {
    [[MMDragonEar sharedInstance] setListening:YES];
}

- (IBAction)stopAudio:(id)sender {
    [[MMDragonEar sharedInstance] setListening:NO];
}

#pragma mark - MMDragonEarDelegate

-(void) willBeginProcessingAudio:(MMDragonEar *)dragonEar{
    
}

-(void) didEndProcessingAudio:(MMDragonEar *)dragonEar{
    
}

-(void) dragonEar:(MMDragonEar *)dragonEar errorProcessingAudio:(NSError *)error{
    NSLog(@"ERROR: %@", error);
}

-(void) dragonEar:(MMDragonEar*)dragonEar didHearResponse:(MMDragonPhrase*)response{
    NSLog(@"RESPONSE:");
    NSLog(@" - result (%.2f, %d)", response.bestResult.stability, response.bestResult.isFinal);
    SpeechRecognitionAlternative* alt = [response.bestResult.alternativesArray firstObject];

    NSLog(@" - - alt (%.2f, %@)", alt.confidence, alt.transcript);

    if([response isComplete]){
        
        NSArray<NSString*>* userDocumentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docPath = [userDocumentsPaths objectAtIndex:0];
        NSString* outputFile = [[docPath stringByAppendingPathComponent:[response identifier]] stringByAppendingPathExtension:@"plist"];

        if([NSKeyedArchiver archiveRootObject:response toFile:outputFile]){
            NSLog(@"wrote to: %@", outputFile);
        }else{
            NSLog(@"failed to write to: %@", outputFile);
        }
    }
    
    if([response isComplete]){
        [_debugView setPhrase:response];
        
        [_debugView setNeedsDisplay];
        [[_debugView superview] setNeedsLayout];

        CGSize size = [_debugView intrinsicContentSize];
        
        [_debugView setFrame:CGRectMake(0, 0, size.width, size.height)];
        [_scrollView setContentSize:size];
    }
}

@end

