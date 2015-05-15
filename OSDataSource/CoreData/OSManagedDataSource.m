//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "RDataSource_Private.h"
#import "OSManagedDataSource.h"

@interface OSManagedDataSource()
@property(nonatomic, strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@end


@implementation OSManagedDataSource
{

}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSInteger)numberOfSections
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[(NSUInteger) section];
    return sectionInfo.numberOfObjects;
}


- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    self = [super init];
    if (self)
    {
        _fetchedResultsController = fetchedResultsController;
        _fetchedResultsController.delegate = self;
        _objectChanges = [NSMutableDictionary dictionary];
        _sectionChanges = [NSMutableDictionary dictionary];
    }

    return self;
}

- (BOOL)enabledUpdatesForDataSource:(OSDataSource *)dataSource indexPaths:(NSArray *)paths changeType:(NSFetchedResultsChangeType)type
{
    return _sectionChanges != nil && _objectChanges != nil;
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if ([self.fetchUpdatesAvailableDelegate enabledUpdatesForDataSource:self indexPaths:nil changeType:type])
    {
        [self didChangeSectionAtIndex:sectionIndex type:type];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableArray *marr = [NSMutableArray array];
    if (indexPath)
        [marr addObject:indexPath];
    if (newIndexPath)
        [marr addObject:newIndexPath];
    if ([self.fetchUpdatesAvailableDelegate enabledUpdatesForDataSource:self indexPaths:marr changeType:type])
    {
        [self didChangeObjectAtIndexPath:indexPath type:type newIndexPath:newIndexPath];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.fetchUpdatesAvailableDelegate enabledUpdatesForDataSource:self indexPaths:nil changeType:NSFetchedResultsChangeDelete])
    {
        [self didChangeContent];
    }
}

- (void)didChangeSectionAtIndex:(NSUInteger)sectionIndex type:(NSFetchedResultsChangeType)type
{
    if (type == NSFetchedResultsChangeInsert || type == NSFetchedResultsChangeDelete)
    {
        NSMutableIndexSet *changeSet = _sectionChanges[@(type)];
        if (changeSet != nil) {
            [changeSet addIndex:sectionIndex];
        } else {
            _sectionChanges[@(type)] = [[NSMutableIndexSet alloc] initWithIndex:sectionIndex];
        }
    }
}

- (void)didChangeObjectAtIndexPath:(NSIndexPath *)indexPath type:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableArray *changeSet = _objectChanges[@(type)];
    if (changeSet == nil) {
        changeSet = [[NSMutableArray alloc] init];
        _objectChanges[@(type)] = changeSet;
    }

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [changeSet addObject:newIndexPath];
            break;
        case NSFetchedResultsChangeDelete:
            [changeSet addObject:indexPath];
            break;
        case NSFetchedResultsChangeUpdate:
            [changeSet addObject:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [changeSet addObject:@[indexPath, newIndexPath]];
            break;
    }
}

- (void)didChangeContent
{
    NSMutableArray *moves = _objectChanges[@(NSFetchedResultsChangeMove)];
    if (moves.count > 0) {
        NSMutableArray *updatedMoves = [[NSMutableArray alloc] initWithCapacity:moves.count];

        NSMutableIndexSet *insertSections = _sectionChanges[@(NSFetchedResultsChangeInsert)];
        NSMutableIndexSet *deleteSections = _sectionChanges[@(NSFetchedResultsChangeDelete)];
        for (NSArray *move in moves) {
            NSIndexPath *fromIP = move[0];
            NSIndexPath *toIP = move[1];

            if ([deleteSections containsIndex:(NSUInteger) fromIP.section]) {
                if (![insertSections containsIndex:(NSUInteger) toIP.section]) {
                    NSMutableArray *changeSet = _objectChanges[@(NSFetchedResultsChangeInsert)];
                    if (changeSet == nil) {
                        changeSet = [@[toIP] mutableCopy];
                        _objectChanges[@(NSFetchedResultsChangeInsert)] = changeSet;
                    } else {
                        [changeSet addObject:toIP];
                    }
                }
            } else if ([insertSections containsIndex:(NSUInteger) toIP.section]) {
                NSMutableArray *changeSet = _objectChanges[@(NSFetchedResultsChangeDelete)];
                if (changeSet == nil) {
                    changeSet = [@[fromIP] mutableCopy];
                    _objectChanges[@(NSFetchedResultsChangeDelete)] = changeSet;
                } else {
                    [changeSet addObject:fromIP];
                }
            } else {
                [updatedMoves addObject:move];
            }
        }

        if (updatedMoves.count > 0) {
            _objectChanges[@(NSFetchedResultsChangeMove)] = updatedMoves;
        } else {
            [_objectChanges removeObjectForKey:@(NSFetchedResultsChangeMove)];
        }
    }

    NSMutableArray *deletes = _objectChanges[@(NSFetchedResultsChangeDelete)];
    if (deletes.count > 0) {
        NSMutableIndexSet *deletedSections = _sectionChanges[@(NSFetchedResultsChangeDelete)];
        [deletes filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSIndexPath *evaluatedObject, NSDictionary *bindings) {
            return ![deletedSections containsIndex:(NSUInteger) evaluatedObject.section];
        }]];
    }

    NSMutableArray *inserts = _objectChanges[@(NSFetchedResultsChangeInsert)];
    if (inserts.count > 0) {
        NSMutableIndexSet *insertedSections = _sectionChanges[@(NSFetchedResultsChangeInsert)];
        [inserts filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSIndexPath *evaluatedObject, NSDictionary *bindings) {
            return ![insertedSections containsIndex:(NSUInteger) evaluatedObject.section];
        }]];
    }

    [self notifyBatchUpdate:^{
        NSIndexSet *deletedSections = _sectionChanges[@(NSFetchedResultsChangeDelete)];
        if (deletedSections.count > 0) {
            [self notifySectionsRemoved:deletedSections];
        }

        NSIndexSet *insertedSections = _sectionChanges[@(NSFetchedResultsChangeInsert)];
        if (insertedSections.count > 0) {
            [self notifySectionsInserted:insertedSections];
        }

        NSArray *deletedItems = _objectChanges[@(NSFetchedResultsChangeDelete)];
        if (deletedItems.count > 0) {
            [self notifyItemsRemovedAtIndexPaths:deletedItems];
        }

        NSArray *insertedItems = _objectChanges[@(NSFetchedResultsChangeInsert)];
        if (insertedItems.count > 0) {
            [self notifyItemsInsertedAtIndexPaths:insertedItems];
        }

        NSArray *reloadItems = _objectChanges[@(NSFetchedResultsChangeUpdate)];
        if (reloadItems.count > 0) {
            [self notifyItemsRefreshedAtIndexPaths:reloadItems];
        }

        NSArray *moveItems = _objectChanges[@(NSFetchedResultsChangeMove)];
        for (NSArray *paths in moveItems) {
            [self notifyItemMovedFromIndexPath:paths[0] toIndexPath:paths[1]];
        }
    }];

    _objectChanges = nil;
    _sectionChanges = nil;
}

- (void)unlockFRCAtSectionIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(dataSource:didUnlockFRCAtSectionIndex:)])
    {
        [self.delegate dataSource:self didUnlockFRCAtSectionIndex:index];
    }
    _sectionChanges = [NSMutableDictionary new];
    _objectChanges = [NSMutableDictionary new];
}

- (void)lockFRCAtSectionIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(dataSource:didLockFRCAtSectionIndex:)])
    {
        [self.delegate dataSource:self didLockFRCAtSectionIndex:index];
    }
    _sectionChanges = nil;
    _objectChanges = nil;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.delegate getNumberOfItemsInCollectionViewInSection:0 forDataSource:self];
    _objectChanges = [NSMutableDictionary dictionary];
    _sectionChanges = [NSMutableDictionary dictionary];
}

@end