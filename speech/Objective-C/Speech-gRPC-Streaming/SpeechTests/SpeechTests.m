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

@end
