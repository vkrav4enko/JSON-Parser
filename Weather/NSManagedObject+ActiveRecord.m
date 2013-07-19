//
//  NSManagedObject+ActiveRecord.m
//  SchoolInfo
//
//  Created by Владимир on 12.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "NSManagedObject+ActiveRecord.h"



@implementation NSManagedObject (ActiveRecord)

+ (id) createInContext:(NSManagedObjectContext *)context
{
	NSString *entityName = NSStringFromClass([self class]);
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

- (void) deleteInContext:(NSManagedObjectContext *)context
{
	[context deleteObject:self];
	
}

+ (NSUInteger)countInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
	NSString *entityName = NSStringFromClass([self class]);
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];	
	[request setIncludesSubentities:NO];
	[request setIncludesPropertyValues:NO];    
	NSError* error;
	NSUInteger count = [context countForFetchRequest:request error:&error];
    return count;
}

+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
	NSString *entityName = NSStringFromClass([self class]);
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
	[request setIncludesSubentities:NO];
	[request setIncludesPropertyValues:NO];   
	NSError *error = nil;	
    return [context executeFetchRequest:request error:&error];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)value inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest* request = [[NSFetchRequest alloc] init];
	NSString *entityName = NSStringFromClass([self class]);
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
	[request setIncludesSubentities:NO];
	[request setIncludesPropertyValues:NO];
	
	[request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attribute, value]];
	NSError *error = nil;
	return [context executeFetchRequest:request error:&error];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortedBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
    NSString *entityName = NSStringFromClass([self class]);
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
    [request setPredicate:predicate];
	[request setIncludesSubentities:NO];
	[request setFetchBatchSize:6];
	
	NSSortDescriptor *sortBy = [[NSSortDescriptor alloc] initWithKey:sortedBy ascending:ascending];
	[request setSortDescriptors:[NSArray arrayWithObject:sortBy]];
    NSError *error = nil;
	return [context executeFetchRequest:request error:&error];

}
@end
