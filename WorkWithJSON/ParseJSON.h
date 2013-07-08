//
//  ParseJSON.h
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParseJSON : NSObject
@property (nonatomic, strong) NSDictionary *parsedDictionary;
@property (nonatomic, copy) NSString *sourceString;
@property (nonatomic) NSUInteger positionInString;
@property (nonatomic) NSUInteger sourceLength;

-(ParseJSON *) initWithString: (NSString *) str;
- (id)parse;

@end
