//
//  NSArray+MapReduce.m
//  Loose Leaf
//
//  Created by Adam Wulf on 6/18/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import "NSArray+MapReduce.h"


@implementation NSArray (MapReduce)

//NSArray* arr            = [NSArray arrayWithObjects:@"Apple", @"Banana", @"Peanut", @"Tree", NULL];
//NSArray* butters        = [arr map:^(id obj, NSUInteger idx) {
//    return [NSString stringWithFormat:@"%@ Butter", obj];
//}];
- (NSArray*)map:(id (^)(id obj, NSUInteger index))mapfunc {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
        [result addObject:mapfunc([self objectAtIndex:index], index)];
    }
    return result;
}

- (NSArray*)mapWithSelector:(SEL)mapfunc {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [result addObject:[[self objectAtIndex:index] performSelector:mapfunc]];
#pragma clang diagnostic pop
    }
    return result;
}

- (id)reduce:(id (^)(id obj, NSUInteger index, id accum))reducefunc {
    id result = NULL;
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
        result = reducefunc([self objectAtIndex:index], index, result);
    }
    return result;
}

- (NSArray*)filter:(BOOL (^)(id obj, NSUInteger index))filterfunc {
    NSMutableArray* ret = [NSMutableArray array];
    for (NSInteger index = 0; index < [self count]; index++) {
        if(filterfunc(self[index], index)){
            [ret addObject:self[index]];
        }
    }
    return ret;
}

- (BOOL)reduceToBool:(BOOL (^)(id obj, NSUInteger index, BOOL accum))reducefunc {
    BOOL result = NO;
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
        result = reducefunc([self objectAtIndex:index], index, result);
    }
    return result;
}

- (NSInteger)reduceToInteger:(NSInteger (^)(id obj, NSUInteger index, NSInteger accum))reducefunc {
    NSInteger result = 0;
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
        result = reducefunc([self objectAtIndex:index], index, result);
    }
    return result;
}

- (CGFloat)reduceToFloat:(CGFloat (^)(id obj, NSUInteger index, CGFloat accum))reducefunc{
    CGFloat result = 0;
    NSUInteger index;
    for (index = 0; index < [self count]; index++) {
        result = reducefunc([self objectAtIndex:index], index, result);
    }
    return result;
}

@end
