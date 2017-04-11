//
//  MMWordGraphView.m
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMWordGraphView.h"
#import "NSArray+MapReduce.h"

#define kVertMargin 10
#define kHorzMargin 40

@implementation MMWordGraphView{
    CGFloat maxY;
    CGFloat maxX;
    NSMutableArray* labelsForWords;
    NSMutableArray* sublayers;
}

-(instancetype) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.layer.borderColor = [[UIColor redColor] CGColor];
        self.layer.borderWidth = 1;
        labelsForWords = [NSMutableArray array];
        sublayers = [NSMutableArray array];
    }
    return self;
}

-(void) setGraph:(MMDragonGraph *)graph{
    _graph = graph;
    NSLog(@"best phrase: %@", [graph bestPhrase]);
    
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [labelsForWords removeAllObjects];
    [sublayers removeAllObjects];
    
    NSMutableArray* nextWordsToLayout = [NSMutableArray array];
    NSArray* wordsToLayout = [graph startingWords];
    
    UILabel*(^findLabelForWord)(MMDragonWord*) = ^UILabel*(MMDragonWord* word){
        return [labelsForWords reduce:^id(NSDictionary* obj, NSUInteger index, id accum) {
            if([obj[@"word"] isEqual:word]){
                return obj[@"label"];
            }
            return accum;
        }];
    };
    
    CGFloat y = 0;
    CGFloat x = 0;
    CGFloat maxWidth = 0;
    
    while ([wordsToLayout count]){
        x += kHorzMargin;
        y += kVertMargin;
        for (MMDragonWord* word in wordsToLayout) {
            
            UILabel* lbl = findLabelForWord(word);
            
            if(!lbl){
                lbl = [[UILabel alloc] init];
                lbl.text = [word word];
                [lbl sizeToFit];
                lbl.frame = CGRectMake(x, y, CGRectGetWidth([lbl bounds]), CGRectGetHeight([lbl bounds]));
                [self addSubview:lbl];
                y += CGRectGetHeight([lbl bounds]) + kVertMargin;
            }
            
            [labelsForWords addObject:@{@"word" : word, @"label" : lbl}];
            
            maxWidth = MAX(maxWidth, CGRectGetWidth([lbl bounds]));
            
            [nextWordsToLayout addObjectsFromArray:[word nextWords]];
        }
        
        x += maxWidth + kHorzMargin;
        maxWidth = 0;
        y = 0;
        wordsToLayout = [nextWordsToLayout copy];
        [nextWordsToLayout removeAllObjects];
    }
    
    for (NSDictionary* wordLbl in labelsForWords) {
        MMDragonWord* word = wordLbl[@"word"];
        UILabel* wordLabel = wordLbl[@"label"];
        
        for (MMDragonWord* nextWord in [word nextWords]) {
            UILabel* nextLabel = findLabelForWord(nextWord);
            
            UIBezierPath* path = [UIBezierPath bezierPath];
            CGPoint startPoint = CGPointMake(CGRectGetMaxX([wordLabel frame]), CGRectGetMidY([wordLabel frame]));
            CGPoint endPoint = CGPointMake(CGRectGetMinX([nextLabel frame]), CGRectGetMidY([nextLabel frame]));
            [path moveToPoint:startPoint];
            [path addLineToPoint:endPoint];
            
            CAShapeLayer* shapeLayer = [CAShapeLayer layer];
            [shapeLayer setPath:[path CGPath]];
            [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
            [shapeLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
            [shapeLayer setLineWidth:1];
            [shapeLayer setStrokeColor:[[UIColor lightGrayColor] CGColor]];

            UILabel* timing = [[UILabel alloc] init];
            [timing setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
            [timing setText:[NSString stringWithFormat:@"%.3f", nextWord.start - word.stop]];
            [timing sizeToFit];
            timing.center = CGPointMake((endPoint.x + startPoint.x)/2, (endPoint.y + startPoint.y)/2);
            [self addSubview:timing];
            
            [[self layer] addSublayer:shapeLayer];
            [sublayers addObject:shapeLayer];
        }
    }
    
    maxY = y;
    maxX = x;
}

-(CGSize) intrinsicContentSize{
    return CGSizeMake(maxX, maxY);
}

@end
