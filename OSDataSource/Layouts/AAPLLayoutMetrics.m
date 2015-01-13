/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Classes used to define the layout metrics.
  
 */

#import "AAPLLayoutMetrics_Private.h"

NSString *const RCollectionElementKindPlaceholder = @"RCollectionElementKindPlaceholder";
CGFloat const AAPLRowHeightVariable = -1000;
CGFloat const AAPLRowHeightRemainder = -1001;
NSInteger const AAPLGlobalSection = NSIntegerMax;

@implementation OSLayoutSupplementaryMetrics

- (NSString *)reuseIdentifier
{
    if (_reuseIdentifier)
        return _reuseIdentifier;

    return NSStringFromClass(_supplementaryViewClass);
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    OSLayoutSupplementaryMetrics *item = [[OSLayoutSupplementaryMetrics alloc] init];
    if (!item)
        return nil;

    item->_reuseIdentifier = [_reuseIdentifier copy];
    item->_height = _height;
    item->_visibleWhileShowingPlaceholder = _visibleWhileShowingPlaceholder;
    item->_supplementaryViewClass = _supplementaryViewClass;
    item->_createView = _createView;
    item->_configureView = _configureView;
    return item;
}

- (void)configureWithBlock:(AAPLLayoutSupplementaryItemConfigurationBlock)block
{
    NSParameterAssert(block != nil);

    if (!_configureView)
    {
        self.configureView = block;
        return;
    }

    // chain the old with the new
    AAPLLayoutSupplementaryItemConfigurationBlock oldConfigBlock = _configureView;
    self.configureView = ^(UICollectionReusableView *view, OSDataSource *dataSource, NSIndexPath *indexPath) {
        oldConfigBlock(view, dataSource, indexPath);
        block(view, dataSource, indexPath);
    };
}

@end

@implementation OSLayoutSectionMetrics
{
    struct
    {
        unsigned int showsSectionSeparatorWhenLastSection : 1;
        unsigned int backgroundColor : 1;
        unsigned int selectedBackgroundColor : 1;
        unsigned int separatorColor : 1;
        unsigned int sectionSeparatorColor : 1;
    } _flags;
}

+ (instancetype)metrics
{
    return [[self alloc] init];
}

+ (instancetype)defaultMetrics
{
    OSLayoutSectionMetrics *metrics = [[self alloc] init];
    metrics.rowHeight = 44;
    return metrics;
}

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _rowHeight = 0;
    // If there's more than one column AND there's a separator color specified, we want to show a column separator by default.
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    OSLayoutSectionMetrics *metrics = [[OSLayoutSectionMetrics alloc] init];
    if (!metrics)
        return nil;

    metrics->_rowHeight = _rowHeight;
    metrics->_hasPlaceholder = _hasPlaceholder;
    metrics->_headers = [_headers copy];
    metrics->_footers = [_footers copy];
    metrics->_flags = _flags;
    return metrics;
}

- (OSLayoutSupplementaryMetrics *)newHeader
{
    OSLayoutSupplementaryMetrics *header = [[OSLayoutSupplementaryMetrics alloc] init];
    if (!_headers)
        _headers = @[header];
    else
        _headers = [_headers arrayByAddingObject:header];
    return header;
}

- (OSLayoutSupplementaryMetrics *)newFooter
{
    OSLayoutSupplementaryMetrics *footer = [[OSLayoutSupplementaryMetrics alloc] init];
    if (!_footers)
        _footers = @[footer];
    else
        _footers = [_footers arrayByAddingObject:footer];
    return footer;
}

- (void)applyValuesFromMetrics:(OSLayoutSectionMetrics *)metrics
{
    if (!metrics)
        return;

    if (metrics.rowHeight)
        self.rowHeight = metrics.rowHeight;

    if (metrics.hasPlaceholder)
        self.hasPlaceholder = YES;

    if (metrics.headers)
    {
        NSArray *headers = [NSArray arrayWithArray:self.headers];
        self.headers = [headers arrayByAddingObjectsFromArray:metrics.headers];
    }

    if (metrics.footers)
    {
        NSArray *footers = self.footers;
        self.footers = [metrics.footers arrayByAddingObjectsFromArray:footers];
    }
}

@end