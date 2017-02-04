//
//  MMPhraseDebugView.m
//  Speech
//
//  Created by Adam Wulf on 2/3/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import "MMPhraseDebugView.h"
#import "NSArray+MapReduce.h"
#import "NSArray+Helper.h"

#define kRowHeight 20
#define kWidthForTimestamp 80
#define kWidthForConfidence 80

@implementation MMPhraseDebugView{
    UIFont* font;
}

-(instancetype) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.layer.borderColor = [[UIColor redColor] CGColor];
        self.layer.borderWidth = 2;

        font = [UIFont systemFontOfSize:12];
        
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    
    return self;
}

-(NSArray<NSNumber*>*)columnWidths{
    NSDictionary* attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:12] };

    return [[[self phrase] debugEventData] reduce:^id(NSDictionary *obj, NSUInteger index, id accum) {
        NSArray<NSArray<NSDictionary*>*>* columnData = obj[@"response"];
        
        NSArray* columnWidths = [columnData map:^id(NSArray<NSDictionary *> *resultColumn, NSUInteger index) {
            CGFloat columnWidth = [resultColumn reduceToFloat:^CGFloat(NSDictionary *obj, NSUInteger index, CGFloat accum) {
                return MAX([obj[@"text"] sizeWithAttributes:attributes].width, accum);
            }];
            
            return @(columnWidth);
        }];
        
        NSArray* ret = @[];
        
        for (NSInteger index=0; index < [accum count] || index < [columnWidths count]; index++) {
            CGFloat maxSoFar = 0;
            CGFloat currWidth = 0;
            
            if(index < [accum count]){
                maxSoFar = [accum[index] floatValue];
            }
            
            if(index < [columnWidths count]){
                currWidth = [columnWidths[index] floatValue];
            }
            
            ret = [ret arrayByAddingObject:@(MAX(maxSoFar, currWidth))];
        }
        
        return ret;
    }];
}

-(CGSize) intrinsicContentSize{
    NSArray<NSDictionary*>* debugData = [[self phrase] debugEventData];
    
    UIScrollView* parent = (UIScrollView*)[self superview];

    NSArray<NSNumber*>* columnWidths = [self columnWidths];
    
    
    CGFloat totalWidth = [columnWidths reduceToFloat:^CGFloat(NSNumber *obj, NSUInteger index, CGFloat accum) {
        return accum + [obj floatValue];
    }];

    
    
    return CGSizeMake(MAX(CGRectGetWidth([parent bounds]), totalWidth + kWidthForTimestamp), [debugData count] * kRowHeight);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    NSDictionary* attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:12] };

    NSArray<NSNumber*>* columnWidths = [self columnWidths];

    [[UIColor darkGrayColor] setFill];
    
    CGFloat widthSoFar = kWidthForTimestamp;
    for (NSNumber* width in columnWidths) {
        CGRect line = CGRectMake(widthSoFar, 0, 1, CGRectGetHeight([self bounds]));
        
        [[UIBezierPath bezierPathWithRect:line] fill];
        
        widthSoFar += [width floatValue];
        
        widthSoFar += kWidthForConfidence;
    }
    
    

    NSArray<NSDictionary*>* debugData = [[self phrase] debugEventData];
    NSTimeInterval startTimestamp = [[debugData firstObject][@"timestamp"] doubleValue];
    
    CGFloat y = 0;
    
    for (NSDictionary* event in debugData) {
        NSTimeInterval eventTimestamp = [event[@"timestamp"] doubleValue];
        NSString* timestampStr = [NSString stringWithFormat:@"%.4f", eventTimestamp - startTimestamp];

        [timestampStr drawAtPoint:CGPointMake(10, y + 4) withAttributes:attributes];
        
        NSArray<NSArray<NSDictionary*>*>* columns = event[@"response"];
        
        CGFloat widthSoFar = kWidthForTimestamp;
        
        for (NSInteger index = 0; index < [columns count]; index++) {
            CGFloat columnWidth = [columnWidths[index] floatValue];
            NSArray* column = columns[index];
            NSDictionary* mostProbableResult = [column firstObject];
            NSString* text = mostProbableResult[@"text"];
            NSString* confidence = [mostProbableResult[@"confidence"] stringValue];
            
            if(text){
                [confidence drawAtPoint:CGPointMake(widthSoFar, y + 4) withAttributes:attributes];

                widthSoFar += kWidthForConfidence;
                
                [text drawAtPoint:CGPointMake(widthSoFar, y + 4) withAttributes:attributes];
            }
            
            widthSoFar += columnWidth;
        }
        
        y += kRowHeight;
    }
}

@end
