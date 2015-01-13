/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Classes used to define the layout metrics.
  
 */

#import <UIKit/UIKit.h>

extern NSString *const RCollectionElementKindPlaceholder;
extern NSInteger const AAPLGlobalSection;

@class OSDataSource;

typedef UICollectionReusableView *(^AAPLLayoutSupplementaryItemCreationBlock)(UICollectionView *collectionView, NSString *kind, NSString *identifier, NSIndexPath *indexPath);

typedef void (^AAPLLayoutSupplementaryItemConfigurationBlock)(UICollectionReusableView *view, OSDataSource *dataSource, NSIndexPath *indexPath);

/// Definition of how supplementary views should be created and presented in a collection view.
@interface OSLayoutSupplementaryMetrics : NSObject <NSCopying>

/// Should this supplementary view be displayed while the placeholder is visible?
@property(nonatomic) BOOL visibleWhileShowingPlaceholder;

/// The height of the supplementary view. If set to 0, the view will be measured to determine its optimal height.
@property(nonatomic) CGFloat height;

/// The class to use when dequeuing an instance of this supplementary view
@property(nonatomic) Class supplementaryViewClass;

/// Optional reuse identifier. If not specified, this will be inferred from the class of the supplementary view.
@property(nonatomic, copy) NSString *reuseIdentifier;

/// An optional block used to create an instance of the supplementary view.
@property(nonatomic, copy) AAPLLayoutSupplementaryItemCreationBlock createView;

/// A block that can be used to configure the supplementary view after it is created.
@property(nonatomic, copy) AAPLLayoutSupplementaryItemConfigurationBlock configureView;

/// Add a configuration block to the supplementary view. This does not clear existing configuration blocks.
- (void)configureWithBlock:(AAPLLayoutSupplementaryItemConfigurationBlock)block;

@end


/// Definition of how a section within a collection view should be presented.
@interface OSLayoutSectionMetrics : NSObject <NSCopying>

@property(nonatomic) BOOL hasPlaceholder;

@property(nonatomic, strong) NSArray *headers;

@property(nonatomic, strong) NSArray *footers;

/// The height of each row in the section. A value of AAPLRowHeightVariable will cause the layout to invoke -collectionView:sizeFittingSize:forItemAtIndexPath: on the data source for each cell. Sections will inherit a default value from the data source of 44.
@property(nonatomic) CGFloat rowHeight;

/// Create a new header associated with a specific data source
- (OSLayoutSupplementaryMetrics *)newHeader;

/// Create a new footer associated with a specific data source.
- (OSLayoutSupplementaryMetrics *)newFooter;

/// Update these metrics with the values from another metrics.
- (void)applyValuesFromMetrics:(OSLayoutSectionMetrics *)metrics;

/// Create a metrics instance
+ (instancetype)metrics;

/// Create a default metrics instance
+ (instancetype)defaultMetrics;
@end
