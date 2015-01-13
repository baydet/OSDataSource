//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OSDataSource.h"
#import "AAPLContentLoading.h"


@interface OSManagedDataSource : OSDataSource
{
    NSMutableArray *_sectionChanges;
    NSMutableArray *_objectChanges;
}

@property(nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

- (void)unlockFRCAtSectionIndex:(NSInteger)index;

- (void)lockFRCAtSectionIndex:(NSInteger)index;
@end