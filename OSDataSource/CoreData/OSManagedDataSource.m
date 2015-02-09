//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "RDataSource_Private.h"
#import "AAPLContentLoading.h"
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

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    self = [super init];
    if (self)
    {
        _fetchedResultsController = fetchedResultsController;
        _sectionChanges = [NSMutableArray array];
        _objectChanges = [NSMutableArray array];
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
        [self didChangeSectionAtIndex:sectionIndex type:type sectionChanges:_sectionChanges];
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
        [self didChangeObjectAtIndexPath:indexPath type:type newIndexPath:newIndexPath objectChangesArray:_objectChanges];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.fetchUpdatesAvailableDelegate enabledUpdatesForDataSource:self indexPaths:nil changeType:0])
    {
        [self didChangeContentWithSectionChanges:_sectionChanges objectChanges:_objectChanges];
    }
}

- (void)didChangeSectionAtIndex:(NSUInteger)sectionIndex type:(NSFetchedResultsChangeType)type sectionChanges:(NSMutableArray *)sectionChanges
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
    [sectionChanges addObject:change];
}

- (void)didChangeObjectAtIndexPath:(NSIndexPath *)indexPath type:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath objectChangesArray:(NSMutableArray *)array
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            change[@(NSFetchedResultsChangeUpdate)] = indexPath;
            break;
    }
    [array addObject:change];
}

- (void)didChangeContentWithSectionChanges:(NSMutableArray *)sectionChanges objectChanges:(NSMutableArray *)objectChanges
{
    NSMutableArray *objectChangesCopy = [objectChanges copy];
    NSMutableArray *sectionChangesCopy = [sectionChanges copy];

    if ([sectionChangesCopy count] > 0)
    {
        [self notifyBatchUpdate:^{
            for (NSDictionary *change in sectionChangesCopy)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {

                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self notifySectionsInserted:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self notifySectionsRemoved:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self notifySectionsRefreshed:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeMove:
                            break;
                    }
                }];
            }
        }];
    }

    if ([objectChangesCopy count] > 0 && [sectionChangesCopy count] == 0)
    {

        if ([self shouldReloadCollectionViewToPreventKnownIssue:objectChangesCopy])
        {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self notifyDidReloadData];

        } else
        {
            [self notifyBatchUpdate:^{

                for (NSDictionary *change in objectChangesCopy)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {

                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self notifyItemsInsertedAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self notifyItemsRemovedAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self notifyItemsRefreshedAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self notifyItemMovedFromIndexPath:obj[0] toIndexPaths:obj[1]];
                                break;
                        }
                    }];
                }
            }];
        }
    }

    [sectionChanges removeAllObjects];
    [objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue:(NSArray *)objectChanges
{
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in objectChanges)
    {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type)
            {
                case NSFetchedResultsChangeInsert:
                    shouldReload = [self.delegate getNumberOfItemsInCollectionViewInSection:indexPath.section forDataSource:self] == 0;
                    break;
                case NSFetchedResultsChangeDelete:
                    shouldReload = [self.delegate getNumberOfItemsInCollectionViewInSection:indexPath.section forDataSource:self] == 1;
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }

    return shouldReload;
}

- (void)unlockFRCAtSectionIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(dataSource:didUnlockFRCAtSectionIndex:)])
    {
        [self.delegate dataSource:self didUnlockFRCAtSectionIndex:index];
    }
    _sectionChanges = [NSMutableArray array];
    _objectChanges = [NSMutableArray array];
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
}
@end