//
//  SpeechTests.m
//  SpeechTests
//
//  Created by Adam Wulf on 4/11/17.
//  Copyright © 2017 Google. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MMDragonPhrase.h"
#import "MMDragonGraph.h"
#import "NSArray+MapReduce.h"

@interface SpeechTests : XCTestCase

@end

@implementation SpeechTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testYeahCoffee {
    // Test to make sure a changed word retains the start of the word it replaces
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"coffee-test" ofType:@"plist"];
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:[unarchivedResponse debugEventData]];
    
    NSArray<NSString*>* strWords = [[graph startingWords] mapWithSelector:@selector(word)];
    
    XCTAssertEqual([[graph startingWords] count], 2);
    XCTAssertTrue([strWords containsObject:@"yeah"], @"contains yeah");
    XCTAssertTrue([strWords containsObject:@"Yucca"], @"contains yeah");
    
    MMDragonWord* yeah = [[graph startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        return [[obj word] isEqualToString:@"yeah"] ? obj : accum;
    }];
    
    XCTAssertEqual([[yeah nextWords] count], 2);
    
    strWords = [[yeah nextWords] mapWithSelector:@selector(word)];
    XCTAssertTrue([strWords containsObject:@"cause"], @"contains yeah");
    XCTAssertTrue([strWords containsObject:@"coffee"], @"contains yeah");

    MMDragonWord* word1 = [yeah nextWords][0];
    MMDragonWord* word2 = [yeah nextWords][1];

    XCTAssertNotEqual([word1 start], 0);
    XCTAssertEqual([word1 start], [word2 start]);
    XCTAssertNotEqual([word1 stop], [word2 stop]);
}

- (void)testPopsicles {
    // Test to make sure that introducing two word phrase will adjust the start
    // of the 2nd word in that phrase
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"popsicles" ofType:@"plist"];
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:[unarchivedResponse debugEventData]];
    
    NSArray<NSString*>* strWords = [[graph startingWords] mapWithSelector:@selector(word)];
    
    XCTAssertEqual([[graph startingWords] count], 2);
    XCTAssertTrue([strWords containsObject:@"I"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"I'll"], @"contains correct word");
    
    MMDragonWord* I = [[graph startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        return [[obj word] isEqualToString:@"I"] ? obj : accum;
    }];
    
    XCTAssertEqual([[I nextWords] count], 1);

    MMDragonWord* like = [I nextWords][0];
    
    XCTAssertEqual([[like nextWords] count], 3);

    strWords = [[like nextWords] mapWithSelector:@selector(word)];
    XCTAssertTrue([strWords containsObject:@"pie"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"popsicle"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"popsicles"], @"contains correct word");
    
    MMDragonWord* popsicles = [like nextWordFor:@"popsicles"];

    strWords = [[popsicles nextWords] mapWithSelector:@selector(word)];
    XCTAssertTrue([strWords containsObject:@"there"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"they're"], @"contains correct word");
    
    MMDragonWord* there = [popsicles nextWordFor:@"there"];
    MMDragonWord* theyre = [popsicles nextWordFor:@"they're"];
    
    XCTAssertEqual([[there nextWords] count], 1);
    XCTAssertEqual([[theyre nextWords] count], 1);
    
    // not just equal in values, but physically the same object
    XCTAssertEqual([there nextWords][0], [theyre nextWords][0]);
}


- (void)testPopsiclesWithRepeatingWords {
    // Test to make sure that introducing two word phrase will adjust the start
    // of the 2nd word in that phrase
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"popsicles" ofType:@"plist"];
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSArray<NSDictionary*>* debugData = [unarchivedResponse debugEventData];
    debugData = [debugData map:^id(NSDictionary *moment, NSUInteger index) {
        if(moment[@"response"]){
            NSMutableDictionary* check = [NSMutableDictionary dictionaryWithDictionary:moment];
            check[@"response"] = [check[@"response"] map:^id(NSArray<NSDictionary*>* arr, NSUInteger index) {
                return [arr map:^id(NSDictionary *obj, NSUInteger index) {
                    if([obj[@"text"] isEqualToString:@"I like popsicles they're really good"]){
                        NSMutableDictionary* mutObj = [NSMutableDictionary dictionaryWithDictionary:obj];
                        mutObj[@"text"] = @"I like popsicles they're really really really good";
                        return mutObj;
                    }
                    if([obj[@"text"] isEqualToString:@" they're really good"]){
                        NSMutableDictionary* mutObj = [NSMutableDictionary dictionaryWithDictionary:obj];
                        mutObj[@"text"] = @" they're really really really good";
                        return mutObj;
                    }
                    return obj;
                }];
            }];
            return check;
        }
        return moment;
    }];
    
    MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:debugData];
    
    NSArray<NSString*>* strWords = [[graph startingWords] mapWithSelector:@selector(word)];
    
    XCTAssertEqual([[graph startingWords] count], 2);
    XCTAssertTrue([strWords containsObject:@"I"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"I'll"], @"contains correct word");
    
    MMDragonWord* I = [[graph startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        return [[obj word] isEqualToString:@"I"] ? obj : accum;
    }];
    
    XCTAssertEqual([[I nextWords] count], 1);
    
    MMDragonWord* like = [I nextWords][0];
    
    XCTAssertEqual([[like nextWords] count], 3);
    
    strWords = [[like nextWords] mapWithSelector:@selector(word)];
    XCTAssertTrue([strWords containsObject:@"pie"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"popsicle"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"popsicles"], @"contains correct word");
    
    MMDragonWord* popsicles = [like nextWordFor:@"popsicles"];
    
    strWords = [[popsicles nextWords] mapWithSelector:@selector(word)];
    XCTAssertTrue([strWords containsObject:@"there"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"they're"], @"contains correct word");
    
    MMDragonWord* there = [popsicles nextWordFor:@"there"];
    MMDragonWord* theyre = [popsicles nextWordFor:@"they're"];
    
    XCTAssertEqual([[there nextWords] count], 1);
    XCTAssertEqual([[theyre nextWords] count], 1);
    
    // not just equal in values, but physically the same object
    XCTAssertEqual([there nextWords][0], [theyre nextWords][0]);
    
    MMDragonWord* really1 = [theyre nextWordFor:@"really"];
    
    XCTAssertNotNil(really1);

    MMDragonWord* really2 = [really1 nextWordFor:@"really"];
    
    XCTAssertNotNil(really2);

    MMDragonWord* really3 = [really2 nextWordFor:@"really"];
    
    XCTAssertNotNil(really3);

    MMDragonWord* good = [really2 nextWordFor:@"really"];

    XCTAssertNotNil(good);
}


- (void)testEarlyForkMerge {
    // Test to make sure that introducing two word phrase will adjust the start
    // of the 2nd word in that phrase
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"duplicate-start" ofType:@"plist"];
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSArray<NSDictionary*>* debugData = [unarchivedResponse debugEventData];
    MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:debugData];
    
    NSArray<NSString*>* strWords = [[graph startingWords] mapWithSelector:@selector(word)];
    
    XCTAssertTrue([strWords containsObject:@"why"], @"contains correct word");
    XCTAssertTrue([strWords containsObject:@"Why"], @"contains correct word");
    
    MMDragonWord* why = [[graph startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        return [[obj word] isEqualToString:@"why"] ? obj : accum;
    }];

    MMDragonWord* Why = [[graph startingWords] reduce:^id(id obj, NSUInteger index, id accum) {
        return [[obj word] isEqualToString:@"Why"] ? obj : accum;
    }];
    
    XCTAssertNotNil(why);
    XCTAssertNotNil(Why);
    
    XCTAssertNotNil([why nextWordFor:@"did"]);
    XCTAssertNotNil([Why nextWordFor:@"did"]);
    
    // not just equal in values, but physically the same object
    XCTAssertEqual([why nextWordFor:@"did"], [Why nextWordFor:@"did"]);
}


- (void)testMergeForks {
    // Test that the "and" and "in" after award merge together afterwards
    // in the merge-forks.plist test case
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"merge-forks" ofType:@"plist"];
    MMDragonPhrase* unarchivedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    MMDragonGraph* graph = [[MMDragonGraph alloc] initWithResponses:[unarchivedResponse debugEventData]];
        
    MMDragonWord* word = [graph startingWordFor:@"Nicki"];
    word = [word nextWordFor:@"Minaj"];
    word = [word nextWordFor:@"Captain's"];
    word = [word nextWordFor:@"trophy"];
    word = [word nextWordFor:@"is"];
    MMDragonWord* in1 = [word nextWordFor:@"in"];
    word = [word nextWordFor:@"an"];
    word = [word nextWordFor:@"award"];
    MMDragonWord* in2 = [word nextWordFor:@"in"];
    MMDragonWord* the1 = [in2 nextWordFor:@"the"];
    MMDragonWord* and = [word nextWordFor:@"and"];
    MMDragonWord* the2 = [and nextWordFor:@"the"];
    
    XCTAssertNotNil(the1, @"found word");
    XCTAssertNotNil(the2, @"found word");
    XCTAssertEqual(the1, the2, @"exact same object");
    
    XCTAssertNotNil(in1, @"found word");
    XCTAssertNotNil(in2, @"found word");
    XCTAssertNotEqual(in1, in2, @"exact same object");
}

@end
