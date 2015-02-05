//
// Created by Sasha Evsyuchenya on 7/8/14.
// Copyright (c) 2014 baydet. All rights reserved.
//

#import "OSPlaceholderFlowLayout.h"
#import "OSDataSource.h"
#import "RDataSource_Private.h"

@interface RPlaceholderLayoutAttributes : UICollectionViewLayoutAttributes
@end

@implementation RPlaceholderLayoutAttributes

- (id)init
{
    self = [super init];
    if (self)
    {

    }

    return self;
}

@end

@interface OSPlaceholderFlowLayout ()
@property(nonatomic) BOOL shouldInsertPlaceholder;
@end

@implementation OSPlaceholderFlowLayout

- (CGSize)collectionViewContentSize
{
    CGSize size = [super collectionViewContentSize];
    for (RPlaceholderLayoutAttributes *attr in self.placeholderMetrics)
    {
        switch (self.scrollDirection)
        {
            case UICollectionViewScrollDirectionVertical:
                size.height += attr.size.height;
                break;
            case UICollectionViewScrollDirectionHorizontal:
                size.width += attr.size.width;
                break;
        }
    }
    return size;
}


- (void)prepareLayout
{
    [super prepareLayout];
    id <UICollectionViewDataSource> o = self.collectionView.dataSource;
    self.placeholderMetrics = [NSMutableArray array];
    self.shouldInsertPlaceholder = NO;
    if ([o isKindOfClass:[OSDataSource class]])
    {
        OSDataSource *dataSource = (OSDataSource *) o;
        for (int i = 0; i < dataSource.numberOfSections; ++i)
        {
            OSDataSource *localDataSource = [dataSource dataSourceForSectionAtIndex:i];
            if (localDataSource.shouldDisplayPlaceholder && [dataSource collectionView:self.collectionView numberOfItemsInSection:i] == 0)
            {
                self.shouldInsertPlaceholder = YES;
                RPlaceholderLayoutAttributes *attributes = [RPlaceholderLayoutAttributes layoutAttributesForSupplementaryViewOfKind:RCollectionElementKindPlaceholder withIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
                attributes.frame = CGRectMake(0, 0, self.collectionView.frame.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right, localDataSource.placeholderMetrics.height);
                [self.placeholderMetrics addObject:attributes];
            }
        }
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    if (self.shouldInsertPlaceholder)
    {
        NSArray *array = [super layoutAttributesForElementsInRect:rect];
        for (UICollectionViewLayoutAttributes *attributes in array)
        {
            if (attributes.representedElementKind == nil)
            {
                attributes.frame = [self layoutAttributesForItemAtIndexPath:attributes.indexPath].frame;
            }
            else
            {
                [self updateAttributes:attributes];
            }
        }
        NSMutableArray *retArr = [NSMutableArray arrayWithArray:array];
        for (RPlaceholderLayoutAttributes *attr in self.placeholderMetrics)
        {
            if ([self shouldInsertPlaceholder:attr intoArr:array])
            {
                [retArr addObject:attr];
            }
        }
        return retArr;
    }
    else
    {
        return [super layoutAttributesForElementsInRect:rect];
    }
}

- (BOOL)shouldInsertPlaceholder:(RPlaceholderLayoutAttributes *)placeholderAttributes intoArr:(NSArray *)arr
{
    CGRect topRect = CGRectZero;
    CGRect bottomRect = CGRectMake(0, self.collectionViewContentSize.height, 0, 0);
    NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        UICollectionViewLayoutAttributes *attr1 = obj1;
        UICollectionViewLayoutAttributes *attr2 = obj2;
        if (attr1.frame.origin.y < attr2.frame.origin.y)
        {
            return NSOrderedAscending;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    for (UICollectionViewLayoutAttributes *attr in sortedArray)
    {
        if ([self attributes:attr abovePlaceholder:placeholderAttributes])
        {
            topRect.size.height = CGRectGetMaxY(attr.frame) - CGRectGetMinY(topRect);
            UIEdgeInsets sectionInsets = [self insetsForSection:attr.indexPath.section];
            if (attr.representedElementKind == nil)
            {
                topRect.size.height += sectionInsets.bottom;
            }
            else if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionHeader] && attr.indexPath.section < placeholderAttributes.indexPath.section)
            {
                topRect.size.height += sectionInsets.bottom + sectionInsets.top;
            }
            else if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionFooter] && ![self sectionHasCells:attr.indexPath.section])
            {
                topRect.size.height += sectionInsets.bottom + sectionInsets.top;
            }
        }
        else
        {
            UIEdgeInsets sectionInsets = [self insetsForSection:attr.indexPath.section];
            CGRect rect = attr.frame;
            if (attr.representedElementKind == nil)
            {
                rect.origin.y -= sectionInsets.top;
            }
            bottomRect = CGRectUnion(bottomRect, rect);
        }
    }

    NSInteger dy = (NSInteger) (CGRectGetMinY(bottomRect) - CGRectGetMaxY(topRect) - [self insetsForSection:placeholderAttributes.indexPath.section].top - [self insetsForSection:placeholderAttributes.indexPath.section].bottom);
    if (dy == placeholderAttributes.frame.size.height)
    {
        CGRect rect = placeholderAttributes.frame;
        rect.origin = CGPointMake(0, CGRectGetMaxY(topRect));
        placeholderAttributes.frame = rect;
        return YES;
    }
    return NO;
}

- (BOOL)sectionHasCells:(NSInteger)section
{
    if ([self.collectionView.dataSource isKindOfClass:[OSDataSource class]])
    {
        OSDataSource *dataSource = (OSDataSource *) self.collectionView.dataSource;
        return [dataSource collectionView:self.collectionView numberOfItemsInSection:section] > 0;
    }
    return NO;
}

- (BOOL)attributes:(UICollectionViewLayoutAttributes *)attributes abovePlaceholder:(RPlaceholderLayoutAttributes *)placeholder
{
    BOOL cond1 = (attributes.indexPath.section < placeholder.indexPath.section) || [attributes.representedElementKind isEqualToString:RCollectionElementKindPlaceholder];
    BOOL cond2 = (attributes.indexPath.section == placeholder.indexPath.section) && [attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader];
    return cond1 || cond2;
}

- (UIEdgeInsets)insetsForSection:(int)index
{
    if ([self.collectionView.delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)] && [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)])
    {
        id <UICollectionViewDelegateFlowLayout> delegate = (id <UICollectionViewDelegateFlowLayout>) self.collectionView.delegate;
        return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:index];
    }
    else
    {
        return self.sectionInset;
    }
}

- (void)updateAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    if (self.shouldInsertPlaceholder)
    {
        CGRect rect = attributes.frame;
        for (RPlaceholderLayoutAttributes *attr in self.placeholderMetrics)
        {
            if (![self attributes:attributes abovePlaceholder:attr])
                rect = [self setOffsetWithFrame:attr.frame toFrame:rect];
        }
        attributes.frame = rect;
    }
}

- (CGRect)setOffsetWithFrame:(CGRect)rect toFrame:(CGRect)frame
{
    CGRect result = frame;
    result.origin.y += rect.size.height;
    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:RCollectionElementKindPlaceholder])
    {
        UICollectionViewLayoutAttributes *o = nil;
        for (UICollectionViewLayoutAttributes *attributes in self.placeholderMetrics)
        {
            if ([attributes.indexPath isEqual:indexPath])
            {
                o = attributes;
                break;
            }
        }
        if (o == nil)
        {
            o = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
            o.frame = CGRectZero;
        }

        return o;
    }
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    [self updateAttributes:attributes];
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self updateAttributes:attributes];
    return attributes;
}


@end