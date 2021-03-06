/*
 Abstract:
 
  A subclass of AAPLDataSource with multiple child data sources. Child data sources may have multiple sections. Load content messages will be sent to all child data sources.
  
 */

#import "AAPLContentLoading.h"
#import "RDataSource_Private.h"
#import "RComposedDataSource.h"
#import "RComposedDataSource_Private.h"
#import "OSPlaceholderView.h"

@interface RComposedDataSource () <RDataSourceDelegate>
@property(nonatomic, retain) NSMutableArray *mappings;
@property(nonatomic, retain) NSMapTable *dataSourceToMappings;
@property(nonatomic, retain) NSMutableDictionary *globalSectionToMappings;
@property(nonatomic, assign) NSUInteger sectionCount;
@property(nonatomic, readonly) NSArray *dataSources;
@property(nonatomic, strong) NSString *aggregateLoadingState;
@end

@implementation RComposedDataSource

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _mappings = [[NSMutableArray alloc] init];
    _dataSourceToMappings = [[NSMapTable alloc] initWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory capacity:1];
    _globalSectionToMappings = [[NSMutableDictionary alloc] init];

    return self;
}

- (id)wrapperForView:(UICollectionView *)collectionView mapping:(AAPLComposedMapping *)mapping
{
    return [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
}

- (void)updateMappings
{
    _sectionCount = 0;
    [_globalSectionToMappings removeAllObjects];

    for (AAPLComposedMapping *mapping in _mappings)
    {
        NSUInteger newSectionCount = [mapping updateMappingsStartingWithGlobalSection:_sectionCount];
        while (_sectionCount < newSectionCount)
            _globalSectionToMappings[@(_sectionCount++)] = mapping;
    }
}

- (NSUInteger)sectionForDataSource:(OSDataSource *)dataSource
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];

    return [mapping globalSectionForLocalSection:0];
}

- (OSDataSource *)dataSourceForSectionAtIndex:(NSInteger)sectionIndex
{
    AAPLComposedMapping *mapping = _globalSectionToMappings[@(sectionIndex)];
    return [mapping.dataSource dataSourceForSectionAtIndex:sectionIndex];
}

- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:globalIndexPath.section];
    return [mapping localIndexPathForGlobalIndexPath:globalIndexPath];
}

- (AAPLComposedMapping *)mappingForGlobalSection:(NSInteger)section
{
    AAPLComposedMapping *mapping = _globalSectionToMappings[@(section)];
    return mapping;
}

- (AAPLComposedMapping *)mappingForDataSource:(OSDataSource *)dataSource
{
    AAPLComposedMapping *mapping = [_dataSourceToMappings objectForKey:dataSource];
    return mapping;
}

- (NSIndexSet *)globalSectionsForLocal:(NSIndexSet *)localSections dataSource:(OSDataSource *)dataSource
{
    NSMutableIndexSet *result = [NSMutableIndexSet indexSet];
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    [localSections enumerateIndexesUsingBlock:^(NSUInteger localSection, BOOL *stop) {
        [result addIndex:[mapping globalSectionForLocalSection:localSection]];
    }];
    return result;
}

- (NSArray *)globalIndexPathsForLocal:(NSArray *)localIndexPaths dataSource:(OSDataSource *)dataSource
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[localIndexPaths count]];
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    for (NSIndexPath *localIndexPath in localIndexPaths)
    {
        [result addObject:[mapping globalIndexPathForLocalIndexPath:localIndexPath]];
    }

    return result;
}

- (NSArray *)dataSources
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[_dataSourceToMappings count]];
    for (id key in _dataSourceToMappings)
    {
        AAPLComposedMapping *mapping = [_dataSourceToMappings objectForKey:key];
        [result addObject:mapping.dataSource];
    }
    return result;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:indexPath.section];

    NSIndexPath *mappedIndexPath = [mapping localIndexPathForGlobalIndexPath:indexPath];

    return [mapping.dataSource itemAtIndexPath:mappedIndexPath];
}

- (NSArray *)indexPathsForItem:(id)object
{
    NSMutableArray *results = [NSMutableArray array];
    NSArray *dataSources = self.dataSources;

    for (OSDataSource *dataSource in dataSources)
    {
        AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
        NSArray *indexPaths = [dataSource indexPathsForItem:object];

        if (![indexPaths count])
            continue;

        for (NSIndexPath *localIndexPath in indexPaths)
            [results addObject:[mapping globalIndexPathForLocalIndexPath:localIndexPath]];
    }

    return results;
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:indexPath.section];
    OSDataSource *dataSource = mapping.dataSource;
    NSIndexPath *localIndexPath = [mapping localIndexPathForGlobalIndexPath:indexPath];

    [dataSource removeItemAtIndexPath:localIndexPath];
}

#pragma mark - AAPLComposedDataSource API

- (void)addDataSource:(OSDataSource *)dataSource
{
    NSParameterAssert(dataSource != nil);

    dataSource.delegate = self;

    AAPLComposedMapping *mappingForDataSource = [_dataSourceToMappings objectForKey:dataSource];
    NSAssert(mappingForDataSource == nil, @"tried to add data source more than once: %@", dataSource);

    mappingForDataSource = [[AAPLComposedMapping alloc] initWithDataSource:dataSource];
    [_mappings addObject:mappingForDataSource];
    [_dataSourceToMappings setObject:mappingForDataSource forKey:dataSource];

    [self updateMappings];
    NSMutableIndexSet *addedSections = [NSMutableIndexSet indexSet];
    NSUInteger numberOfSections = dataSource.numberOfSections;

    for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; ++sectionIdx)
        [addedSections addIndex:[mappingForDataSource globalSectionForLocalSection:sectionIdx]];
}

- (void)removeDataSource:(OSDataSource *)dataSource
{
    AAPLComposedMapping *mappingForDataSource = [_dataSourceToMappings objectForKey:dataSource];
    NSAssert(mappingForDataSource != nil, @"Data source not found in mapping");

    NSMutableIndexSet *removedSections = [NSMutableIndexSet indexSet];
    NSUInteger numberOfSections = dataSource.numberOfSections;

    for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; ++sectionIdx)
        [removedSections addIndex:[mappingForDataSource globalSectionForLocalSection:sectionIdx]];

    [_dataSourceToMappings removeObjectForKey:dataSource];
    [_mappings removeObject:mappingForDataSource];

    dataSource.delegate = nil;

    [self updateMappings];
}

#pragma mark - RDataSource methods

- (NSInteger)numberOfSections
{
    [self updateMappings];
    return _sectionCount;
}

- (OSLayoutSectionMetrics *)snapshotMetricsForSectionAtIndex:(NSInteger)sectionIndex
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:sectionIndex];
    NSInteger localSection = [mapping localSectionForGlobalSection:sectionIndex];
    OSDataSource *dataSource = mapping.dataSource;

    OSLayoutSectionMetrics *metrics = [dataSource snapshotMetricsForSectionAtIndex:localSection];
    OSLayoutSectionMetrics *enclosingMetrics = [super snapshotMetricsForSectionAtIndex:sectionIndex];

    [enclosingMetrics applyValuesFromMetrics:metrics];
    return enclosingMetrics;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];

    for (OSDataSource *dataSource in self.dataSources)
        [dataSource registerReusableViewsWithCollectionView:collectionView];
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeFittingSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:indexPath.section];
    UICollectionView *wrapper = [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
    OSDataSource *dataSource = mapping.dataSource;
    NSIndexPath *localIndexPath = [mapping localIndexPathForGlobalIndexPath:indexPath];

    return [dataSource collectionView:wrapper sizeFittingSize:size forItemAtIndexPath:localIndexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForHeaderFittingSize:(CGSize)size atSectionIndex:(NSUInteger)sectionIndex
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:sectionIndex];
    UICollectionView *wrapper = [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
    OSDataSource *dataSource = mapping.dataSource;
    NSUInteger localSection = [mapping localSectionForGlobalSection:sectionIndex];

    return [dataSource collectionView:wrapper sizeForHeaderFittingSize:size atSectionIndex:localSection];
}

- (CGSize)collectionView:(UICollectionView *)collectionView sizeForFooterFittingSize:(CGSize)size atSectionIndex:(NSUInteger)sectionIndex
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:sectionIndex];
    UICollectionView *wrapper = [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
    OSDataSource *dataSource = mapping.dataSource;
    NSUInteger localSection = [mapping localSectionForGlobalSection:sectionIndex];

    return [dataSource collectionView:wrapper sizeForFooterFittingSize:size atSectionIndex:localSection];
}

#pragma mark - AAPLContentLoading

- (void)updateLoadingState
{
    // let's find out what our state should be by asking our data sources
    NSInteger numberOfLoading = 0;
    NSInteger numberOfRefreshing = 0;
    NSInteger numberOfError = 0;
    NSInteger numberOfLoaded = 0;
    NSInteger numberOfNoContent = 0;

    NSArray *loadingStates = [self.dataSources valueForKey:@"loadingState"];
    loadingStates = [loadingStates arrayByAddingObject:[super loadingState]];

    for (NSString *state in loadingStates)
    {
        if ([state isEqualToString:AAPLLoadStateLoadingContent])
            numberOfLoading++;
        else if ([state isEqualToString:AAPLLoadStateRefreshingContent])
            numberOfRefreshing++;
        else if ([state isEqualToString:AAPLLoadStateError])
            numberOfError++;
        else if ([state isEqualToString:AAPLLoadStateContentLoaded])
            numberOfLoaded++;
        else if ([state isEqualToString:AAPLLoadStateNoContent])
            numberOfNoContent++;
    }

//    NSLog(@"Composed.loadingState: loading = %d  refreshing = %d  error = %d  no content = %d  loaded = %d", numberOfLoading, numberOfRefreshing, numberOfError, numberOfNoContent, numberOfLoaded);

    // Always prefer loading
    if (numberOfLoading)
        _aggregateLoadingState = AAPLLoadStateLoadingContent;
    else if (numberOfRefreshing)
        _aggregateLoadingState = AAPLLoadStateRefreshingContent;
    else if (numberOfError)
        _aggregateLoadingState = AAPLLoadStateError;
    else if (numberOfNoContent)
        _aggregateLoadingState = AAPLLoadStateNoContent;
    else if (numberOfLoaded)
        _aggregateLoadingState = AAPLLoadStateContentLoaded;
    else
        _aggregateLoadingState = AAPLLoadStateInitial;
}

- (NSString *)loadingState
{
    if (!_aggregateLoadingState)
        [self updateLoadingState];
    return _aggregateLoadingState;
}

- (void)setLoadingState:(NSString *)loadingState
{
    _aggregateLoadingState = nil;
    [super setLoadingState:loadingState];
}

- (void)loadContent
{
    for (OSDataSource *dataSource in self.dataSources)
        [dataSource loadContent];
}

- (void)resetContent
{
    _aggregateLoadingState = nil;
    [super resetContent];
    for (OSDataSource *dataSource in self.dataSources)
        [dataSource resetContent];
}

- (void)stateDidChange
{
    [super stateDidChange];
    [self updateLoadingState];
}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self updateMappings];

    AAPLComposedMapping *mapping = [self mappingForGlobalSection:section];
    UICollectionView *wrapper = [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
    NSInteger localSection = [mapping localSectionForGlobalSection:section];
    OSDataSource *dataSource = mapping.dataSource;

    NSInteger numberOfSections = [dataSource numberOfSectionsInCollectionView:wrapper];
    NSAssert(localSection < numberOfSections, @"local section is out of bounds for composed data source");

    // If we're showing the placeholder, ignore what the child data sources have to say about the number of items.
    if (self.obscuredByPlaceholder)
        return 0;

    return [dataSource collectionView:wrapper numberOfItemsInSection:localSection];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLComposedMapping *mapping = [self mappingForGlobalSection:indexPath.section];
    UICollectionView *wrapper = [AAPLComposedViewWrapper wrapperForView:collectionView mapping:mapping];
    OSDataSource *dataSource = mapping.dataSource;
    NSIndexPath *localIndexPath = [mapping localIndexPathForGlobalIndexPath:indexPath];

    return [dataSource collectionView:wrapper cellForItemAtIndexPath:localIndexPath];
}

#pragma mark - AAPLDataSourceDelegate

- (NSInteger)getNumberOfItemsInCollectionViewInSection:(NSInteger)section forDataSource:(OSDataSource *)dataSource
{
    NSIndexSet *set = [self globalSectionsForLocal:[NSIndexSet indexSetWithIndex:(NSUInteger) section] dataSource:dataSource];
    return [self.delegate getNumberOfItemsInCollectionViewInSection:set.firstIndex forDataSource:dataSource];
}

- (void)dataSource:(OSDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    NSArray *globalIndexPaths = [mapping globalIndexPathsForLocalIndexPaths:indexPaths];

    [self notifyItemsInsertedAtIndexPaths:globalIndexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    NSArray *globalIndexPaths = [mapping globalIndexPathsForLocalIndexPaths:indexPaths];

    [self notifyItemsRemovedAtIndexPaths:globalIndexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    NSArray *globalIndexPaths = [mapping globalIndexPathsForLocalIndexPaths:indexPaths];

    [self notifyItemsRefreshedAtIndexPaths:globalIndexPaths];
}

- (void)dataSource:(OSDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];
    NSIndexPath *globalFromIndexPath = [mapping globalIndexPathForLocalIndexPath:fromIndexPath];
    NSIndexPath *globalNewIndexPath = [mapping globalIndexPathForLocalIndexPath:newIndexPath];

    [self notifyItemMovedFromIndexPath:globalFromIndexPath toIndexPath:globalNewIndexPath];
}

- (void)dataSource:(OSDataSource *)dataSource didInsertSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];

    [self updateMappings];

    NSMutableIndexSet *globalSections = [NSMutableIndexSet indexSet];
    [sections enumerateIndexesUsingBlock:^(NSUInteger localSectionIndex, BOOL *stop) {
        [globalSections addIndex:[mapping globalSectionForLocalSection:localSectionIndex]];
    }];

    [self notifySectionsInserted:globalSections direction:direction];
}

- (void)dataSource:(OSDataSource *)dataSource didRemoveSections:(NSIndexSet *)sections direction:(AAPLDataSourceSectionOperationDirection)direction
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];

    [self updateMappings];

    NSMutableIndexSet *globalSections = [NSMutableIndexSet indexSet];
    [sections enumerateIndexesUsingBlock:^(NSUInteger localSectionIndex, BOOL *stop) {
        [globalSections addIndex:[mapping globalSectionForLocalSection:localSectionIndex]];
    }];

    [self notifySectionsRemoved:globalSections direction:direction];
}

- (void)dataSource:(OSDataSource *)dataSource didRefreshSections:(NSIndexSet *)sections
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];

    NSMutableIndexSet *globalSections = [NSMutableIndexSet indexSet];
    [sections enumerateIndexesUsingBlock:^(NSUInteger localSectionIndex, BOOL *stop) {
        [globalSections addIndex:[mapping globalSectionForLocalSection:localSectionIndex]];
    }];

    [self notifySectionsRefreshed:globalSections];
    [self updateMappings];
}

- (void)dataSource:(OSDataSource *)dataSource didMoveSection:(NSInteger)section toSection:(NSInteger)newSection direction:(AAPLDataSourceSectionOperationDirection)direction
{
    AAPLComposedMapping *mapping = [self mappingForDataSource:dataSource];

    NSInteger globalSection = [mapping globalSectionForLocalSection:section];
    NSInteger globalNewSection = [mapping globalSectionForLocalSection:newSection];

    [self updateMappings];

    [self notifySectionMovedFrom:globalSection to:globalNewSection direction:direction];
}

- (void)dataSourceDidReloadData:(OSDataSource *)dataSource
{
    [self notifyDidReloadData];
}

- (void)dataSource:(OSDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    [self notifyBatchUpdate:update complete:complete];
}

/// If the content was loaded successfully, the error will be nil.
- (void)dataSource:(OSDataSource *)dataSource didLoadContentWithError:(NSError *)error
{
    BOOL showingPlaceholder = self.shouldDisplayPlaceholder;
    [self updateLoadingState];

    // We were showing the placehoder and now we're not
    if (showingPlaceholder && !self.shouldDisplayPlaceholder)
        [self notifyBatchUpdate:^{
            [self executePendingUpdates];
        }];

    [self notifyContentLoadedWithError:error];
}

/// Called just before a datasource begins loading its content.
- (void)dataSourceWillLoadContent:(OSDataSource *)dataSource
{
    [self updateLoadingState];
    [self notifyWillLoadContent];
}

- (void)dataSource:(OSDataSource *)dataSource didLockFRCAtSectionIndex:(NSInteger)sectionIndex
{
}

- (void)dataSource:(OSDataSource *)dataSource didUnlockFRCAtSectionIndex:(NSInteger)sectionIndex
{
}

- (void)dataSourceNeedsInvalidateLayout:(OSDataSource *)dataSource
{
    [self notifyNeedsInvalidateLayout];
}

- (void)updatePlaceholder:(AAPLCollectionPlaceholderView *)placeholderView atSectionIndex:(NSInteger)sectionIndex notifyVisibility:(BOOL)notify
{
    NSIndexPath *localSectionIndex = [self localIndexPathForGlobalIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
    [[self dataSourceForSectionAtIndex:sectionIndex] updatePlaceholder:placeholderView atSectionIndex:localSectionIndex.section notifyVisibility:notify];
}

@end
