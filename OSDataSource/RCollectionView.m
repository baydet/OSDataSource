//
// Created by Alexandr Evsyuchenya on 3/12/14.
// Copyright (c) 2014 baydet. All rights reserved.
//

#import "RCollectionView.h"


@implementation RCollectionView

#pragma mark - NSFetchedResultsControllerDelegate protocol

#pragma mark - RDataSourceDelegate methods

- (void)dataSource:(OSDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self deleteItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self insertItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self reloadItemsAtIndexPaths:indexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self moveItemAtIndexPath:fromIndexPath toIndexPath:newIndexPath];
}

- (void)dataSource:(OSDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    [self insertSections:sections];
}

- (void)dataSource:(OSDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    [self deleteSections:sections];
}

- (void)dataSource:(OSDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction
{
    [self moveSection:section toSection:newSection];
}

- (void)dataSource:(OSDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    [self performBatchUpdates:update completion:(void (^)(BOOL)) complete];
}

- (void)dataSource:(OSDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections
{
    [self reloadSections:sections];
}

- (void)dataSourceDidReloadData:(OSDataSource *)dataSource
{
    [self reloadData];
}

- (void)dataSource:(OSDataSource *)dataSource didLoadContentWithError:(NSError *)error
{
}

- (void)dataSourceWillLoadContent:(OSDataSource *)dataSource
{

}

- (void)dataSourceNeedsInvalidateLayout:(OSDataSource *)dataSource
{
    [self.collectionViewLayout invalidateLayout];
}

- (NSInteger)getNumberOfItemsInCollectionViewInSection:(NSInteger)section forDataSource:(OSDataSource *)dataSource
{
    return [self numberOfItemsInSection:section];
}


@end