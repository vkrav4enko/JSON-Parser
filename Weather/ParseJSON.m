//
//  ParseJSON.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "ParseJSON.h"

@interface ParseJSON ()

- (BOOL)hasMoreCharacters;
- (unichar)lookAtNextCharacter;
- (unichar)getNextCharacter;

- (void)skipCharacter;
- (void)skipSpaces;


- (NSString *)parseString;
- (NSNumber *)parseTrue;
- (NSNumber *)parseFalse;
- (NSNumber *)parseNumber;
- (NSArray *)parseArray;
- (NSDictionary *)parseDictionary;
- (id)parseObject;

@end

@implementation ParseJSON

- (ParseJSON *)initWithString:(NSString *)str
{
    self = [super init];
    if (self) {
        _sourceString = str;
        _sourceLength = [str length];
    }
    return self;
}

-(BOOL)hasMoreCharacters
{
    return (_positionInString < _sourceString.length);
}

-(unichar)lookAtNextCharacter
{
    return [_sourceString characterAtIndex:_positionInString];
}

- (unichar)getNextCharacter
{
    return [_sourceString characterAtIndex:_positionInString++];
}

- (NSString *)getNextString:(NSUInteger)length
{
    if (_positionInString + length > _sourceString.length) {
        @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                       reason:@"Unexpected end of source string."
                                     userInfo:nil];
    }
    NSString *str = [_sourceString substringWithRange:NSMakeRange(_positionInString, length)];
    _positionInString += length;
    return str;
}


- (void)skipCharacter
{
    _positionInString++;
}

- (void)skipSpaces
{
    while ([self hasMoreCharacters])
    {
        unichar c = [self lookAtNextCharacter];
        
        if(!isspace((int) c))
            break;
        
        [self skipCharacter];        
    }
}

-(NSString *)parseString
{
    unichar c1 = [self getNextCharacter];
    
    int quotersType;     
    
    if (c1 == '"') {
        quotersType = 0;
    } else if (c1 == '\'') {
        quotersType = 1;
    } else {
        @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                       reason:@"Illegal string start character."
                                     userInfo:nil];
    }
    
    NSMutableString *resultString = [NSMutableString string];
    
    BOOL isEscaped = NO;
    while ([self hasMoreCharacters]) {
        unichar c = [self getNextCharacter];
        if ((!isEscaped && (quotersType == 0 && c == '"')) || (quotersType == 1 && c == '\'')) {
            break;
        }
        if (!isEscaped) {
            if (c == '\\') {
                isEscaped = YES;
            } else {
                [resultString appendFormat:@"%C", c];
            }
        } else {
            if (c == '"') {
                [resultString appendString:@"\""];
            } else if (c == '\'') {
                [resultString appendString:@"'"];
            } else if (c == '/') {
                [resultString appendString:@"/"];
            } else if (c == 'b') {
                [resultString appendString:@"\b"];
            } else if (c == 'f') {
                [resultString appendString:@"\f"];
            } else if (c == 'n') {
                [resultString appendString:@"\n"];
            } else if (c == 'r') {
                [resultString appendString:@"\r"];
            } else if (c == 't') {
                [resultString appendString:@"\t"];
            } else {
                @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                               reason:[NSString stringWithFormat:@"Illegal string escaped character (%C).", c]
                                             userInfo:nil];
            }
            isEscaped = NO;
        }
    }
    
    return resultString;

}



- (NSNumber *)parseTrue
{
    NSString *str = [self getNextString:4];
    
    if (![str isEqualToString:@"true"]) {
        @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                       reason:@"Illegal character appeared."
                                     userInfo:nil];
    }
    
    return [NSNumber numberWithBool:YES];
}

- (NSNumber *)parseFalse
{
    NSString *str = [self getNextString:5];
    
    if (![str isEqualToString:@"false"]) {
        @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                       reason:@"Illegal character appeared."
                                     userInfo:nil];
    }
    
    return [NSNumber numberWithBool:NO];
}

- (NSNumber *)parseNumber
{
    NSCharacterSet *numberSet = [NSCharacterSet characterSetWithCharactersInString:@"+-.eE0123456789"];
    
    NSMutableString *numberStr = [NSMutableString string];
    
    BOOL isFloat = NO;
    
    while ([self hasMoreCharacters]) {
        unichar c = [self lookAtNextCharacter];
        if (![numberSet characterIsMember:c]) {
            break;
        }
        if (c == '.' || c == 'e' || c == 'E') {
            isFloat = YES;
        }
        [numberStr appendFormat:@"%C", c];
        [self skipCharacter];
    }
    
    NSNumber *resultNumber;
    NSScanner *scanner = [NSScanner scannerWithString:numberStr];
    
    if (isFloat) {
        float floatValue;
        if ([scanner scanFloat:&floatValue]) {
            resultNumber = [NSNumber numberWithFloat:floatValue];
        } else {
            @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                           reason:@"Illegal number format."
                                         userInfo:nil];
        }
    } else {
        int intValue;
        if ([scanner scanInt:&intValue]) {
            resultNumber = [NSNumber numberWithInt:intValue];
        } else {
            @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                           reason:@"Illegal number format."
                                         userInfo:nil];
        }
    }
    
    return resultNumber;
}


- (NSArray *)parseArray
{
    NSMutableArray *resultArray = [NSMutableArray array];
    
    [self skipCharacter];   // '['
    
    while (YES) {
        [self skipSpaces];
        
        // Check for empty array
        if ([self lookAtNextCharacter] == ']') {
            [self skipCharacter];
            break;
        }
        
        id anObj = [self parseObject];
        [resultArray addObject:anObj];
        
        [self skipSpaces];
        
        unichar c = [self getNextCharacter];
        if (c == ']') {
            break;
        } else if (c != ',') {
            @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                           reason:@"Illegal array entry divider."
                                         userInfo:nil];
        }
    }
    
    return resultArray;
}

- (NSDictionary *)parseDictionary
{
    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
    
    [self skipCharacter];   // '{'
    
    while (YES) {
        [self skipSpaces];
        
        // Check for empty dictionary
        if ([self lookAtNextCharacter] == '}') {
            [self skipCharacter];
            break;
        }
        
        NSString *keyStr = [self parseString];
        
        [self skipSpaces];
        
        unichar c1 = [self getNextCharacter];
        if (c1 != ':') {
            @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                           reason:@"Missing ':' after a key of a hash table."
                                         userInfo:nil];
        }
        
        [self skipSpaces];
        
        id valueObj = [self parseObject];
        
        [resultDictionary setObject:valueObj forKey:keyStr];
        
        [self skipSpaces];
        
        unichar c2 = [self getNextCharacter];
        if (c2 == '}') {
            break;
        } else if (c2 != ',') {
            @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                           reason:@"Illegal hash table entry divider."
                                         userInfo:nil];
        }
    }
    
    return resultDictionary;
}

- (id)parseObject
{
    [self skipSpaces];
    
    unichar c = [self lookAtNextCharacter];
    
    if (c == '"' || c == '\'') {
        NSString *str = [self parseString];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"dd-mm-yyyy HH:mm:ss"];
         NSDate *date = [dateFormatter dateFromString:str ];
        
        if (date)
            return date;
        else
            return str;
    } else if (c == '[') {
        return [self parseArray];
    } else if (c == '{') {
        return [self parseDictionary];
    } else if (isdigit((int)c) || c == '-' || c == '+' || c == '.') {
        return [self parseNumber];
    } else if (c == 't') {
        return [self parseTrue];
    } else if (c == 'f') {
        return [self parseFalse];
    } else {
        @throw [NSException exceptionWithName:@"JSON Parsing Error"
                                       reason:[NSString stringWithFormat:@"Illegal Object Prefix"]
                                     userInfo:nil];
    }
    
    return nil;
}

- (id)parse
{
    id result = nil;
    @try {
        _positionInString = 0;
        result = [self parseObject];
    }
    @catch (NSException *e) {
        NSLog(@"JSON Parsing Error: %@", [e reason]);
    }
    return result;
}
















@end
