//
//  NSManagedObject+ActiveRecord.h
//  SchoolInfo
//
//  Created by Владимир on 12.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (ActiveRecord)

+ (instancetype) createInContext:(NSManagedObjectContext *)context;
- (void) deleteInContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countInContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortedBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

@end
