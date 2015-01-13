/*
 Abstract:
 
  The base data source class.
  
  This file contains methods used internally by subclasses. These methods are not considered part of the public API of OSDataSource. It is possible to implement fully functional data sources without using these methods.
  
 */

#import "OSDataSource.h"

@protocol RDataSourceDelegate;
@class AAPLCollectionPlaceholderView;

typedef enum
{
    AAPLDataSourceSectionOperationDirectionNone = 0,
    AAPLDataSourceSectionOperationDirectionLeft,
    AAPLDataSourceSectionOperationDirectionRight,
} AAPLDataSourceSectionOperationDirection;


@interface OSDataSource ()
- (AAPLCollectionPlaceholderView *)dequeuePlaceholderViewForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;


- (void)updatePlaceholder:(AAPLCollectionPlaceholderView *)placeholderView atSectionIndex:(NSInteger)sectionIndex notifyVisibility:(BOOL)notify;

- (void)stateWillChange;

- (void)stateDidChange;

- (void)enqueuePendingUpdateBlock:(dispatch_block_t)block;

- (void)executePendingUpdates;

- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath;

/// Is this data source the root data source? This depends on proper set up of the delegate property. Container data sources ALWAYS act as the delegate for their contained data sources.
@property(nonatomic, readonly, getter = isRootDataSource) BOOL rootDataSource;

/// Whether this data source should display the placeholder.
@property(nonatomic, readonly) BOOL shouldDisplayPlaceholder;

/// A delegate object that will receive change notifications from this data source.

- (void)notifySectionsInserted:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction;

- (void)notifySectionsRemoved:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction;

- (void)notifySectionMovedFrom:(NSInteger)section to:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction;

@end

@protocol RDataSourceDelegate <NSObject>
@required
- (NSInteger)getNumberOfItemsInCollectionViewInSection:(NSInteger)section forDataSource:(OSDataSource *)dataSource;

@optional

- (void)dataSource:(OSDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths;

- (void)dataSource:(OSDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths;

- (void)dataSource:(OSDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths;

- (void)dataSource:(OSDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath;

- (void)dataSource:(OSDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction;

- (void)dataSource:(OSDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction;

- (void)dataSource:(OSDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction;

- (void)dataSource:(OSDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections;

- (void)dataSourceDidReloadData:(OSDataSource *)dataSource;

- (void)dataSourceNeedsInvalidateLayout:(OSDataSource *)dataSource;

- (void)dataSource:(OSDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete;

/// If the content was loaded successfully, the error will be nil.
- (void)dataSource:(OSDataSource *)dataSource didLoadContentWithError:(NSError *)error;

/// Called just before a datasource begins loading its content.
- (void)dataSourceWillLoadContent:(OSDataSource *)dataSource;

- (void)dataSource:(OSDataSource *)dataSource didLockFRCAtSectionIndex:(NSInteger)sectionIndex;

- (void)dataSource:(OSDataSource *)dataSource didUnlockFRCAtSectionIndex:(NSInteger)sectionIndex;

@end
