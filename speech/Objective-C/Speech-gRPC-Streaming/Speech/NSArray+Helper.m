//
//  NSArray+Helper.m
//  EngParser
//
//  Created by Adam Wulf on 4/26/13.
//  Copyright (c) 2013 Milestone Made LLC. All rights reserved.
//

#import "NSArray+Helper.h"

@implementation NSArray (Helper)

-(id) firstObject{
    if([self count]){
        return [self objectAtIndex:0];
    }
    return nil;
}

-(id) secondObject{
    if([self count] > 1){
        return [self objectAtIndex:1];
    }
    return nil;
}


-(NSArray*) objectsFromIndex:(NSInteger)indx{
    if(indx < [self count]){
        return [self subarrayWithRange:NSMakeRange(indx, [self count] - indx)];
    }
    return nil;
}


-(NSArray*) objectsToIndex:(NSInteger)indx{
    if(indx < 0){
        return nil;
    }
    if(indx <= [self count]){
        return [self subarrayWithRange:NSMakeRange(0, indx)];
    }
    return nil;
}

-(NSArray*) cons:(NSObject *)obj{
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self];
    [arr addObject:obj];
    return [NSArray arrayWithArray:arr];
}

-(NSArray*) cdr{
    if([self count] > 0){
        return [self objectsToIndex:[self count] - 1];
    }
    return [NSArray array];
}

-(id) lastObjectOfClass:(Class)aClass{
    for(int i=(int)[self count]-1;i>=0;i--){
        if([[self objectAtIndex:i] isKindOfClass:aClass]){
            return [self objectAtIndex:i];
        }
    }
    return nil;
}

- (NSArray *)arrayByRemovingObject:(id)anObject{
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self];
    [arr removeObject:anObject];
    return [NSArray arrayWithArray:arr];
}

- (NSArray *)arrayByRemovingLastObject{
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self];
    if([self count]){
        [arr removeObjectAtIndex:[self count] - 1];
    }
    return [NSArray arrayWithArray:arr];
}

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)index{
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self];
    [arr removeObjectAtIndex:index];
    return [NSArray arrayWithArray:arr];
}

-(id) objectAfter:(NSObject*)obj{
    NSUInteger index = [self indexOfObject:obj];
    if(index == NSNotFound || index >= [self count] - 1){
        return nil;
    }
    return [self objectAtIndex:index + 1];
}

-(id) objectBefore:(NSObject*)obj{
    NSUInteger index = [self indexOfObject:obj];
    if(index == NSNotFound || index <= 0){
        return nil;
    }
    return [self objectAtIndex:index - 1];
}

-(NSArray*) arrayByRemovingDuplicates{
    return [[NSOrderedSet orderedSetWithArray:self] array];
}

-(NSArray*) reversedArray{
    return [[self reverseObjectEnumerator] allObjects];
}


@end


@implementation NSMutableArray (Helper)

-(void) reverseArray{
    NSUInteger count = [self count];
    
    for (int i = 0; i < count / 2; ++i)
    {
        NSUInteger j = count - i - 1;
        
        id tempObject = [self objectAtIndex:i];
        
        [self replaceObjectAtIndex:i withObject:[self objectAtIndex:j]];
        [self replaceObjectAtIndex:j withObject:tempObject];
    }
}

-(void) moveObjectAtIndex:(NSUInteger)index1 toIndex:(NSUInteger)index2{
    id obj = [self objectAtIndex:index1];
    [self removeObjectAtIndex:index1];
    [self insertObject:obj atIndex:index2];
}

@end
