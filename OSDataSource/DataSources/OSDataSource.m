/*
 Abstract:
 
  The base data source class.
  
 */

#import "AAPLContentLoading.h"
#import "RDataSource_Private.h"
#import "OSPlaceholderView.h"
#import "NSObject+KVOBlock.h"
#import <libkern/OSAtomic.h>

#define OS_ASSERT_MAIN_THREAD NSAssert([NSThread isMainThread], @"This method must be called on the main thread")

@interface OSDataSource () <OSStateMachineDelegate>
@property(nonatomic, strong) NSMutableArray *headers;
@property(nonatomic, strong) NSMutableDictionary *headersByKey;
@property(nonatomic, strong) AAPLLoadableContentStateMachine *stateMachine;
@property(nonatomic, strong) AAPLCollectionPlaceholderView *placeholderView;
@property(nonatomic, copy) dispatch_block_t pendingUpdateBlock;
@property(nonatomic) BOOL loadingComplete;
@property(nonatomic, weak) AAPLLoading *loadingInstance;
@end

@implementation OSDataSource
{
}

@synthesize loadingError = _loadingError;

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _defaultMetrics = [[OSLayoutSectionMetrics alloc] init];
    _checkedItems = [NSMutableArray array];

    self.fetchUpdatesAvailableDelegate = self;
    return self;
}

- (BOOL)isRootDataSource
{
    id delegate = self.delegate;
    return ![delegate isKindOfClass:[OSDataSource class]];
}


- (OSDataSource *)dataSourceForSectionAtIndex:(NSInteger)sectionIndex
{
    return self;
}

- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath
{
    return globalIndexPath;
}

- (NSArray *)indexPathsForItem:(id)object
{
    NSAssert(NO, @"Should be implemented by subclasses");
    return nil;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Should be implemented by subclasses");
    return nil;
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Should be implemented by subclasses");
    return;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    NSInteger numberOfSections = self.numberOfSections;

    OSLayoutSectionMetrics *globalMetrics = [self snapshotMetricsForSectionAtIndex:AAPLGlobalSection];
    for (OSLayoutSupplementaryMetrics *headerMetrics in globalMetrics.headers)
        [collectionView registerClass:headerMetrics.supplementaryViewClass forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerMetrics.reuseIdentifier];

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex)
    {
        OSLayoutSectionMetrics *metrics = [self snapshotMetricsForSectionAtIndex:sectionIndex];

        for (OSLayoutSupplementaryMetrics *headerMetrics in metrics.headers)
            [collectionView registerClass:headerMetrics.supplementaryViewClass forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerMetrics.reuseIdentifier];
        for (OSLayoutSupplementaryMetrics *footerMetrics in metrics.footers)
            [collectionView registerClass:footerMetrics.supplementaryViewClass forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerMetrics.reuseIdentifier];
    }

    [collectionView registerClass:[AAPLCollectionPlaceholderView class] forSupplementaryViewOfKind:RCollectionElementKindPlaceholder withReuseIdentifier:NSStringFromClass([AAPLCollectionPlaceholderView class])];
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeFittingSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Should be implemented by subclasses");
    return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionVIew sizeForHeaderFittingSize:(CGSize)size atSectionIndex:(NSUInteger)sectionIndex
{
    OSLayoutSectionMetrics *metrics = _sectionMetrics[@(sectionIndex)];
    OSLayoutSupplementaryMetrics *metrics1 = [metrics.headers firstObject];
    if (metrics1 == nil)
        return CGSizeZero;
    else
    {
        CGFloat height = metrics1.height;
        return CGSizeMake(size.width, height);
    }
}

- (OSLayoutSupplementaryMetrics *)placeholderMetrics
{
    if (!_placeholderMetrics)
    {
        OSLayoutSupplementaryMetrics *supplementaryMetrics = [OSLayoutSupplementaryMetrics new];
        _placeholderMetrics = supplementaryMetrics;
    }
    return _placeholderMetrics;
}


#pragma mark - AAPLContentLoading methods

- (AAPLLoadableContentStateMachine *)stateMachine
{
    if (_stateMachine)
        return _stateMachine;

    _stateMachine = [[AAPLLoadableContentStateMachine alloc] init];
    _stateMachine.delegate = self;
    return _stateMachine;
}

- (NSString *)loadingState
{
    // Don't cause the creation of the state machine just by inspection of the loading state.
    if (!_stateMachine)
        return AAPLLoadStateInitial;
    return _stateMachine.currentState;
}

- (void)setLoadingState:(NSString *)loadingState
{
    AAPLLoadableContentStateMachine *stateMachine = self.stateMachine;
    if (loadingState != stateMachine.currentState)
        stateMachine.currentState = loadingState;
}

- (void)beginLoading
{
    self.loadingComplete = NO;
    self.loadingState = (([self.loadingState isEqualToString:AAPLLoadStateInitial] || [self.loadingState isEqualToString:AAPLLoadStateLoadingContent]) ? AAPLLoadStateLoadingContent : AAPLLoadStateRefreshingContent);

    [self notifyWillLoadContent];
}

- (void)endLoadingWithState:(NSString *)state error:(NSError *)error update:(dispatch_block_t)update
{
    self.loadingError = error;
    self.loadingState = state;

    if (self.shouldDisplayPlaceholder)
    {
        if (update)
            [self enqueuePendingUpdateBlock:update];
    }
    else
    {
        [self notifyBatchUpdate:^{
            // Run pending updates
            [self executePendingUpdates];
            if (update)
                update();
        }];
    }

    self.loadingComplete = YES;
    [self notifyContentLoadedWithError:error];
}

- (void)setNeedsLoadContent
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadContent) object:nil];
    [self performSelector:@selector(loadContent) withObject:nil afterDelay:0];
}

- (void)resetContent
{
    _stateMachine = nil;
    // Content has been reset, if we're loading something, chances are we don't need it.
    self.loadingInstance.current = NO;
}

- (void)loadContent
{
    // To be implemented by subclasses…
}

- (void)loadContentWithBlock:(AAPLLoadingBlock)block
{
    [self beginLoading];

    __weak typeof(&*self) weakself = self;

    AAPLLoading *loading = [AAPLLoading loadingWithCompletionHandler:^(NSString *newState, NSError *error, AAPLLoadingUpdateBlock update) {
        if (!newState)
            return;

        [self endLoadingWithState:newState error:error update:^{
            OSDataSource *me = weakself;
            if (update && me)
                update(me);
        }];
    }];

    // Tell previous loading instance it's no longer current and remember this loading instance
    self.loadingInstance.current = NO;
    self.loadingInstance = loading;

    // Call the provided block to actually do the load
    block(loading);
}

- (void)whenLoaded:(dispatch_block_t)block
{
    __block int32_t complete = 0;

    [self aapl_addObserverForKeyPath:@"loadingComplete" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew withBlock:^(id obj, NSDictionary *change, id observer) {

        BOOL loadingComplete = [change[NSKeyValueChangeNewKey] boolValue];
        if (!loadingComplete)
            return;

        [self aapl_removeObserver:observer];

        // Already called the completion handler
        if (!OSAtomicCompareAndSwap32(0, 1, &complete))
            return;

        block();
    }];
}

- (BOOL)shouldReloadSection
{
    return YES;
}

- (void)stateWillChange
{
    // loadingState property isn't really Key Value Compliant, so let's begin a change notification
    [self willChangeValueForKey:@"loadingState"];
}

- (void)stateDidChange
{
    // loadingState property isn't really Key Value Compliant, so let's finish a change notification
    [self didChangeValueForKey:@"loadingState"];
}

- (void)didEnterLoadingState
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:self.shouldReloadSection];
}

- (void)didEnterRefreshingState
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:self.shouldReloadSection];
}

- (void)didEnterLoadedState
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:NO];
}

- (void)didEnterFirstTimeLoad
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:YES];
}

- (void)didEnterNoContentState
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:YES];
}

- (void)didEnterErrorState
{
    [self updatePlaceholder:self.placeholderView atSectionIndex:0 notifyVisibility:YES];
}

#pragma mark - UICollectionView metrics

- (OSLayoutSectionMetrics *)defaultMetrics
{
    if (_defaultMetrics)
        return _defaultMetrics;
    _defaultMetrics = [OSLayoutSectionMetrics defaultMetrics];
    return _defaultMetrics;
}

- (OSLayoutSectionMetrics *)snapshotMetricsForSectionAtIndex:(NSInteger)sectionIndex
{
    if (!_sectionMetrics)
        _sectionMetrics = [NSMutableDictionary dictionary];

    OSLayoutSectionMetrics *metrics = [self.defaultMetrics copy];
    [metrics applyValuesFromMetrics:_sectionMetrics[@(sectionIndex)]];

    // The root data source puts its headers into the special global section. Other data sources put theirs into their 0 section.
    BOOL rootDataSource = self.rootDataSource;
    if (rootDataSource && AAPLGlobalSection == sectionIndex)
    {
        metrics.headers = [NSArray arrayWithArray:_headers];
    }

    // We need to handle global headers and the placeholder view for section 0
    if (!sectionIndex)
    {
        NSMutableArray *headers = [NSMutableArray array];

        if (_headers && !rootDataSource)
            [headers addObjectsFromArray:_headers];

        metrics.hasPlaceholder = self.shouldDisplayPlaceholder;

        if (metrics.headers)
            [headers addObjectsFromArray:metrics.headers];

        metrics.headers = headers;
    }

    return metrics;
}

- (NSDictionary *)snapshotMetrics
{
    NSInteger numberOfSections = self.numberOfSections;
    NSMutableDictionary *metrics = [NSMutableDictionary dictionary];

    UIColor *defaultBackground = [UIColor whiteColor];

    OSLayoutSectionMetrics *globalMetrics = [self snapshotMetricsForSectionAtIndex:AAPLGlobalSection];
    metrics[@(AAPLGlobalSection)] = globalMetrics;

    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex)
    {
        OSLayoutSectionMetrics *sectionMetrics = [self snapshotMetricsForSectionAtIndex:sectionIndex];
        metrics[@(sectionIndex)] = sectionMetrics;
    }

    return metrics;
}

- (OSLayoutSupplementaryMetrics *)headerForKey:(NSString *)key
{
    return _headersByKey[key];
}

- (OSLayoutSupplementaryMetrics *)newHeaderForKey:(NSString *)key
{
    if (!_headers)
        _headers = [NSMutableArray array];
    if (!_headersByKey)
        _headersByKey = [NSMutableDictionary dictionary];

    NSAssert(!_headersByKey[key], @"Attempting to add a header for a key that already exists: %@", key);

    OSLayoutSupplementaryMetrics *header = [[OSLayoutSupplementaryMetrics alloc] init];
    _headersByKey[key] = header;
    [_headers addObject:header];
    return header;
}

- (void)replaceHeaderForKey:(NSString *)key withHeader:(OSLayoutSupplementaryMetrics *)header
{
    if (!_headers)
        _headers = [NSMutableArray array];
    if (!_headersByKey)
        _headersByKey = [NSMutableDictionary dictionary];

    OSLayoutSupplementaryMetrics *oldHeader = _headersByKey[key];
    NSAssert(oldHeader != nil, @"Attempting to replace a header that doesn't exist: key = %@", key);

    NSInteger headerIndex = [_headers indexOfObject:oldHeader];
    _headersByKey[key] = header;
    _headers[headerIndex] = header;
}

- (void)removeHeaderForKey:(NSString *)key
{
    if (!_headers)
        _headers = [NSMutableArray array];
    if (!_headersByKey)
        _headersByKey = [NSMutableDictionary dictionary];

    OSLayoutSupplementaryMetrics *oldHeader = _headersByKey[key];
    NSAssert(oldHeader != nil, @"Attempting to remove a header that doesn't exist: key = %@", key);

    [_headers removeObject:oldHeader];
    [_headersByKey removeObjectForKey:key];
}

- (OSLayoutSupplementaryMetrics *)newHeaderForSectionAtIndex:(NSInteger)sectionIndex
{
    if (!_sectionMetrics)
        _sectionMetrics = [NSMutableDictionary dictionary];

    OSLayoutSectionMetrics *metrics = _sectionMetrics[@(sectionIndex)];
    if (!metrics)
    {
        metrics = [OSLayoutSectionMetrics metrics];
        _sectionMetrics[@(sectionIndex)] = metrics;
    }

    return [metrics newHeader];
}

- (OSLayoutSupplementaryMetrics *)newFooterForSectionAtIndex:(NSInteger)sectionIndex
{
    if (!_sectionMetrics)
        _sectionMetrics = [NSMutableDictionary dictionary];

    OSLayoutSectionMetrics *metrics = _sectionMetrics[@(sectionIndex)];
    if (!metrics)
    {
        metrics = [OSLayoutSectionMetrics metrics];
        _sectionMetrics[@(sectionIndex)] = metrics;
    }

    return [metrics newFooter];
}

#pragma mark - Placeholder

- (BOOL)obscuredByPlaceholder
{
    if (self.shouldDisplayPlaceholder)
        return YES;

    if (!self.delegate)
        return NO;

    if (![self.delegate isKindOfClass:[OSDataSource class]])
        return NO;

    OSDataSource *dataSource = (OSDataSource *) self.delegate;
    return dataSource.obscuredByPlaceholder;
}

- (BOOL)shouldDisplayPlaceholder
{
    NSString *loadingState = self.loadingState;

    // If we're in the error state & have an error message or title
    if ([loadingState isEqualToString:AAPLLoadStateError] && (self.errorMessage || self.errorTitle))
        return YES;

    // Only display a placeholder when we're loading or have no content
    if (![loadingState isEqualToString:AAPLLoadStateLoadingContent] && ![loadingState isEqualToString:AAPLLoadStateNoContent] && ![loadingState isEqualToString:AAPLLoadStateRefreshingContent])
        return NO;

    // Can't display the placeholder if both the title and message are missing
    return !(!_noContentMessage && !_noContentTitle);

}

- (void)updatePlaceholder:(AAPLCollectionPlaceholderView *)placeholderView atSectionIndex:(NSInteger)sectionIndex notifyVisibility:(BOOL)notify
{
    NSString *message;
    NSString *title;

    if (placeholderView)
    {
        NSString *loadingState = self.loadingState;
        [placeholderView showActivityIndicator:([loadingState isEqualToString:AAPLLoadStateLoadingContent] || [loadingState isEqualToString:AAPLLoadStateRefreshingContent])];

        if ([loadingState isEqualToString:AAPLLoadStateNoContent])
        {
            title = _noContentTitle;
            message = _noContentMessage;
            [placeholderView showPlaceholderWithTitle:title message:message image:_noContentImage animated:YES];
        }
        else if ([loadingState isEqualToString:AAPLLoadStateError])
        {
            title = self.errorTitle;
            message = self.errorMessage;
            [placeholderView showPlaceholderWithTitle:title message:message image:self.noContentImage animated:YES];
        }
        else if ([loadingState isEqualToString:AAPLLoadStateRefreshingContent])
            [placeholderView hidePlaceholderAnimated:NO];
        else
            [placeholderView hidePlaceholderAnimated:YES];
    }

    if (notify && (self.noContentTitle || self.noContentMessage || self.errorTitle || self.errorMessage))
        [self notifySectionsRefreshed:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfSections)]];
}

- (AAPLCollectionPlaceholderView *)dequeuePlaceholderViewForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath
{
    if (!_placeholderView)
        _placeholderView = [collectionView dequeueReusableSupplementaryViewOfKind:RCollectionElementKindPlaceholder withReuseIdentifier:NSStringFromClass([AAPLCollectionPlaceholderView class]) forIndexPath:indexPath];
    [self updatePlaceholder:_placeholderView atSectionIndex:indexPath.section notifyVisibility:NO];
    return _placeholderView;
}

#pragma mark - Notification methods

- (void)executePendingUpdates
{
    OS_ASSERT_MAIN_THREAD;
    dispatch_block_t block = _pendingUpdateBlock;
    _pendingUpdateBlock = nil;
    if (block)
        block();
}

- (void)enqueuePendingUpdateBlock:(dispatch_block_t)block
{
    dispatch_block_t update;

    if (_pendingUpdateBlock)
    {
        dispatch_block_t oldPendingUpdate = _pendingUpdateBlock;
        update = ^{
            oldPendingUpdate();
            block();
        };
    }
    else
        update = block;

    self.pendingUpdateBlock = update;
}

- (void)notifyItemsInsertedAtIndexPaths:(NSArray *)insertedIndexPaths
{
    OS_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder)
    {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsInsertedAtIndexPaths:insertedIndexPaths];
        }];
        return;
    }

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)])
    {
        [delegate dataSource:self didInsertItemsAtIndexPaths:insertedIndexPaths];
    }
}

- (void)notifyItemsRemovedAtIndexPaths:(NSArray *)removedIndexPaths
{
    OS_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder)
    {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsRemovedAtIndexPaths:removedIndexPaths];
        }];
        return;
    }

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRemoveItemsAtIndexPaths:)])
    {
        [delegate dataSource:self didRemoveItemsAtIndexPaths:removedIndexPaths];
    }
}

- (void)notifyItemsRefreshedAtIndexPaths:(NSArray *)refreshedIndexPaths
{
    OS_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder)
    {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsRefreshedAtIndexPaths:refreshedIndexPaths];
        }];
        return;
    }

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRefreshItemsAtIndexPaths:)])
    {
        [delegate dataSource:self didRefreshItemsAtIndexPaths:refreshedIndexPaths];
    }
}

- (void)notifyItemMovedFromIndexPath:(NSIndexPath *)indexPath toIndexPaths:(NSIndexPath *)newIndexPath
{
    OS_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder)
    {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemMovedFromIndexPath:indexPath toIndexPaths:newIndexPath];
        }];
        return;
    }

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)])
    {
        [delegate dataSource:self didMoveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

- (void)notifySectionsInserted:(NSIndexSet *)sections
{
    [self notifySectionsInserted:sections direction:AAPLDataSourceSectionOperationDirectionNone];
}

- (void)notifySectionsInserted:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didInsertSections:direction:)])
    {
        [delegate dataSource:self didInsertSections:sections direction:direction];
    }
}

- (void)notifySectionsRemoved:(NSIndexSet *)sections
{
    [self notifySectionsRemoved:sections direction:AAPLDataSourceSectionOperationDirectionNone];
}

- (void)notifySectionsRemoved:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRemoveSections:direction:)])
    {
        [delegate dataSource:self didRemoveSections:sections direction:direction];
    }
}

- (void)notifySectionsRefreshed:(NSIndexSet *)sections
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRefreshSections:)])
    {
        [delegate dataSource:self didRefreshSections:sections];
    }
}

- (void)notifySectionMovedFrom:(NSInteger)section to:(NSInteger)newSection
{
    [self notifySectionMovedFrom:section to:newSection direction:AAPLDataSourceSectionOperationDirectionNone];
}

- (void)notifySectionMovedFrom:(NSInteger)section to:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didMoveSection:toSection:direction:)])
    {
        [delegate dataSource:self didMoveSection:section toSection:newSection direction:direction];
    }
}

- (void)notifyDidReloadData
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceDidReloadData:)])
    {
        [delegate dataSourceDidReloadData:self];
    }
}

- (void)notifyBatchUpdate:(dispatch_block_t)update
{
    [self notifyBatchUpdate:update complete:nil];
}

- (void)notifyBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    OS_ASSERT_MAIN_THREAD;

    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:performBatchUpdate:complete:)])
    {
        [delegate dataSource:self performBatchUpdate:update complete:complete];
    }
    else
    {
        if (update)
        {
            update();
        }
        if (complete)
        {
            complete();
        }
    }
}

- (void)notifyContentLoadedWithError:(NSError *)error
{
    OS_ASSERT_MAIN_THREAD;
    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didLoadContentWithError:)])
    {
        [delegate dataSource:self didLoadContentWithError:error];
    }
}

- (void)notifyNeedsInvalidateLayout
{
    OS_ASSERT_MAIN_THREAD;
    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceNeedsInvalidateLayout:)])
    {
        [delegate dataSourceNeedsInvalidateLayout:self];
    }
}

- (void)notifyWillLoadContent
{
    OS_ASSERT_MAIN_THREAD;
    id <RDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceWillLoadContent:)])
    {
        [delegate dataSourceWillLoadContent:self];
    }
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Should be implemented by subclasses");
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.numberOfSections;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:RCollectionElementKindPlaceholder])
        return [self dequeuePlaceholderViewForCollectionView:collectionView atIndexPath:indexPath];

    NSInteger section;
    NSInteger item;
    OSDataSource *dataSource;

    if (indexPath.length == 1)
    {
        section = AAPLGlobalSection;
        item = [indexPath indexAtPosition:0];
        dataSource = self;
    }
    else
    {
        section = indexPath.section;
        item = indexPath.item;
        dataSource = [self dataSourceForSectionAtIndex:section];
    }

    OSLayoutSectionMetrics *sectionMetrics = [self snapshotMetricsForSectionAtIndex:section];
    OSLayoutSupplementaryMetrics *metrics;

    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        NSArray *headers = sectionMetrics.headers;
        metrics = (item < [headers count]) ? headers[item] : nil;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter])
    {
        NSArray *footers = sectionMetrics.footers;
        metrics = (item < [footers count]) ? footers[item] : nil;
    }

    if (!metrics)
        return nil;

    // Need to map the global index path to an index path relative to the target data source, because we're handling this method at the root of the data source tree. If I allowed subclasses to handle this, this wouldn't be necessary. But because of the way headers layer, it's more efficient to snapshot the section and find the metrics once.
    NSIndexPath *localIndexPath = [self localIndexPathForGlobalIndexPath:indexPath];
    UICollectionReusableView *view;
    if (metrics.createView)
        view = metrics.createView(collectionView, kind, metrics.reuseIdentifier, localIndexPath);
    else
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:metrics.reuseIdentifier forIndexPath:indexPath];

    NSAssert(view != nil, @"Unable to dequeue a reusable view with identifier %@", metrics.reuseIdentifier);
    if (!view)
        return nil;

    if (metrics.configureView)
        metrics.configureView(view, dataSource, localIndexPath);

    return view;
}

#pragma mark - Managing collection rows methods

- (BOOL)enabledUpdatesForDataSource:(OSDataSource *)dataSource indexPaths:(NSArray *)paths changeType:(NSFetchedResultsChangeType)type
{
    return YES;
}

- (void)checkItemAtIndexPath:(NSIndexPath *)path
{
    [_checkedItems addObject:[self itemAtIndexPath:path]];
}

- (void)uncheckItemAtIndexPath:(NSIndexPath *)path
{
    [_checkedItems removeObject:[self itemAtIndexPath:path]];
}

- (NSArray *)selectedItems
{
    return [NSArray arrayWithArray:_checkedItems];
}

@end
