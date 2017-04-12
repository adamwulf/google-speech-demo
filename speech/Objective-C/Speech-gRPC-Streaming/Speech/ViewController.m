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
#import "MMWordGraphView.h"

#define SAMPLE_RATE 16000.0f

@interface ViewController () <MMDragonEarDelegate>
@property (nonatomic, strong) MMPhraseDebugView *debugView;
@property (nonatomic, strong) MMWordGraphView *graphView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableData *audioData;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
    NSArray* arr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"documents directory: %@", arr[0]);
    
    _debugView = [[MMPhraseDebugView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _graphView = [[MMWordGraphView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    _graphView.hidden = YES;
    
    [_scrollView addSubview:_debugView];
    [_scrollView addSubview:_graphView];
    
    [[MMDragonEar sharedInstance] setDelgate:self];
    
    
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:[arr[0] stringByAppendingPathComponent:@"00EDA127-09EA-4BB0-9422-97B1CB997F15.plist"]];
    [self displayResponse:unarchivedResponse];
}

- (IBAction)recordAudio:(id)sender {
    [[MMDragonEar sharedInstance] setListening:YES];
}

- (IBAction)stopAudio:(id)sender {
    [[MMDragonEar sharedInstance] setListening:NO];
}

-(IBAction) viewToggleChangedValue:(UISegmentedControl*)sender{
    if(sender.selectedSegmentIndex == 0){
        _debugView.hidden = NO;
        _graphView.hidden = YES;
    }else{
        _debugView.hidden = YES;
        _graphView.hidden = NO;
    }
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
//    NSLog(@"RESPONSE:");
//    NSLog(@" - result (%.2f, %d)", response.bestResult.stability, response.bestResult.isFinal);
//    SpeechRecognitionAlternative* alt = [response.bestResult.alternativesArray firstObject];
//    NSLog(@" - - alt (%.2f, %@)", alt.confidence, alt.transcript);

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
    
    [self displayResponse:response];
}

-(void) displayResponse:(MMDragonPhrase*)response{
    if([response hasResults]){
        [_debugView setPhrase:response];
        
        [_debugView setNeedsDisplay];
        [[_debugView superview] setNeedsLayout];
        
        CGSize debugSize = [_debugView intrinsicContentSize];
        
        [_debugView setFrame:CGRectMake(0, 0, debugSize.width, debugSize.height)];
        
        
        NSArray<NSDictionary*>* debugData = [response debugEventData];
        
        MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:debugData];
        [_graphView setGraph:graph];
        
        CGSize graphSize = [_graphView intrinsicContentSize];
        
        [_graphView setFrame:CGRectMake(0, 0, graphSize.width, graphSize.height)];
        
        [_scrollView setContentSize:CGSizeMake(MAX(debugSize.width, graphSize.width), MAX(debugSize.height, graphSize.height))];
    }
}

@end

