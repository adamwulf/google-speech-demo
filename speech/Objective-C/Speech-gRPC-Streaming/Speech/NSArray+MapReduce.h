//
//  NSArray+MapReduce.h
//  Loose Leaf
//
//  Created by Adam Wulf on 6/18/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSArray <ObjectType> (MapReduce)

- (NSArray*)map : (id (^)(ObjectType obj, NSUInteger index))mapfunc;
- (NSArray*)mapWithSelector:(SEL)mapfunc;

- (id)reduce:(id (^)(ObjectType obj, NSUInteger index, id accum))reducefunc;
- (BOOL)reduceToBool:(BOOL (^)(ObjectType obj, NSUInteger index, BOOL accum))reducefunc;
- (NSInteger)reduceToInteger:(NSInteger (^)(ObjectType obj, NSUInteger index, NSInteger accum))reducefunc;
- (CGFloat)reduceToFloat:(CGFloat (^)(ObjectType obj, NSUInteger index, CGFloat accum))reducefunc;

- (NSArray<ObjectType>*)filter:(BOOL (^)(ObjectType obj, NSUInteger index))filterfunc;

@end
