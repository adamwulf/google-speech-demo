//
//  MMWordGraphView.m
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMWordGraphView.h"
#import "NSArray+MapReduce.h"

#define kMargin 10

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
    
    CGFloat y = 0;
    CGFloat x = 0;
    CGFloat maxWidth = 0;
    
    while ([wordsToLayout count]){
        x += kMargin;
        y += kMargin;
        for (MMDragonWord* word in wordsToLayout) {
            UILabel* lbl = [[UILabel alloc] init];
            lbl.text = [word word];
            [lbl sizeToFit];
            lbl.frame = CGRectMake(x, y, CGRectGetWidth([lbl bounds]), CGRectGetHeight([lbl bounds]));
            [self addSubview:lbl];
            
            [labelsForWords addObject:@{@"word" : word, @"label" : lbl}];
            
            y += CGRectGetHeight([lbl bounds]) + kMargin;
            maxWidth = MAX(maxWidth, CGRectGetWidth([lbl bounds]));
            
            [nextWordsToLayout addObjectsFromArray:[word nextWords]];
        }
        
        x += maxWidth + kMargin;
        maxWidth = 0;
        y = 0;
        wordsToLayout = [nextWordsToLayout copy];
        [nextWordsToLayout removeAllObjects];
    }
    
    for (NSDictionary* wordLbl in labelsForWords) {
        MMDragonWord* word = wordLbl[@"word"];
        UILabel* wordLabel = wordLbl[@"label"];
        
        for (MMDragonWord* nextWord in [word nextWords]) {
            UILabel* nextLabel = [labelsForWords reduce:^id(NSDictionary* obj, NSUInteger index, id accum) {
                if([obj[@"word"] isEqual:nextWord]){
                    return obj[@"label"];
                }
                return accum;
            }];
            
            UIBezierPath* path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(CGRectGetMaxX([wordLabel frame]), CGRectGetMidY([wordLabel frame]))];
            [path addLineToPoint:CGPointMake(CGRectGetMinX([nextLabel frame]), CGRectGetMidY([nextLabel frame]))];
            
            CAShapeLayer* shapeLayer = [CAShapeLayer layer];
            [shapeLayer setPath:[path CGPath]];
            [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
            [shapeLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
            [shapeLayer setLineWidth:1];
            [shapeLayer setStrokeColor:[[UIColor blackColor] CGColor]];
            
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
