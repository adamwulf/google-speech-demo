//
//  MMPhraseDebugView.m
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMPhraseDebugView.h"

@implementation MMPhraseDebugView

-(CGSize) intrinsicContentSize{
    
    [self phrase];
    
    return CGSizeZero;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
