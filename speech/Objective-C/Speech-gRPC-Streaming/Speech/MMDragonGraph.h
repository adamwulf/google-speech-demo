//
//  MMDragonGraph.h
//  Speech
//
//  Created by Adam Wulf on 4/10/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDragonWord.h"

@interface MMDragonGraph : NSObject

-(instancetype) initWithResponses:(NSArray<NSDictionary*>*)responses;

@property (nonatomic, readonly) NSArray<MMDragonWord*>* startingWords;

-(MMDragonWord*) startingWordFor:(NSString*)stringWord;
-(NSArray<MMDragonWord*>*) bestPhrase;

@end
