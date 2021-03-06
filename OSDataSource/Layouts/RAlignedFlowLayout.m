//
// Created by Alexandr Evsyuchenya on 3/4/14.
// Copyright (c) 2014 baydet. All rights reserved.
//

#import "RAlignedFlowLayout.h"


@interface UICollectionViewLayoutAttributes (LeftAligned)

- (void)leftAlignFrameWithSectionInset:(UIEdgeInsets)sectionInset;

@end

@implementation UICollectionViewLayoutAttributes (LeftAligned)

- (void)leftAlignFrameWithSectionInset:(UIEdgeInsets)sectionInset
{
    CGRect frame = self.frame;
    frame.origin.x = sectionInset.left;
    self.frame = frame;
}

@end

#pragma mark -

@implementation RAlignedFlowLayout

#pragma mark - UICollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributesToReturn = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *attributes in attributesToReturn)
    {
        if (nil == attributes.representedElementKind)
        {
            NSIndexPath *indexPath = attributes.indexPath;
            attributes.frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
        }
    }
    return attributesToReturn;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *currentItemAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    RFlowLayoutAlignment alignment = _contentAlignment;
    if ([self.collectionView.delegate conformsToProtocol:@protocol(RAlignedFlowLayoutDelegate)])
    {
        id <RAlignedFlowLayoutDelegate> delegate = (id <RAlignedFlowLayoutDelegate>) self.collectionView.delegate;
        alignment = [delegate alignmentForFlowLayout:self atIndexPath:indexPath];
    }
    if (alignment == RCenterAlignedLayout)
    {
        return currentItemAttributes;
    }
    else
    {
        UIEdgeInsets sectionInset = [self evaluatedSectionInsetForItemAtIndex:indexPath.section];

        BOOL isFirstItemInSection = indexPath.item == 0;
        CGFloat layoutWidth = CGRectGetWidth(self.collectionView.frame) - sectionInset.left - sectionInset.right;

        if (isFirstItemInSection)
        {
            [currentItemAttributes leftAlignFrameWithSectionInset:sectionInset];
            return currentItemAttributes;
        }

        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
        CGRect previousFrame = [self layoutAttributesForItemAtIndexPath:previousIndexPath].frame;
        CGFloat previousFrameRightPoint = previousFrame.origin.x + previousFrame.size.width;
        CGRect currentFrame = currentItemAttributes.frame;
        CGRect strecthedCurrentFrame = CGRectMake(sectionInset.left,
                currentFrame.origin.y,
                layoutWidth,
                currentFrame.size.height);
        // if the current frame, once left aligned to the left and stretched to the full collection view
        // width intersects the previous frame then they are on the same line
        BOOL isFirstItemInRow = !CGRectIntersectsRect(previousFrame, strecthedCurrentFrame);

        if (isFirstItemInRow)
        {
            // make sure the first item on a line is left aligned
            [currentItemAttributes leftAlignFrameWithSectionInset:sectionInset];
            return currentItemAttributes;
        }

        CGRect frame = currentItemAttributes.frame;
        frame.origin.x = previousFrameRightPoint + [self evaluatedMinimumInteritemSpacingForItemAtIndex:indexPath.row];
        currentItemAttributes.frame = frame;
        return currentItemAttributes;
    }
}

- (CGFloat)evaluatedMinimumInteritemSpacingForItemAtIndex:(NSInteger)index
{
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)])
    {
        id <UICollectionViewDelegateFlowLayout> delegate = (id <UICollectionViewDelegateFlowLayout>) self.collectionView.delegate;

        return [delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:index];
    } else
    {
        return self.minimumInteritemSpacing;
    }
}

- (UIEdgeInsets)evaluatedSectionInsetForItemAtIndex:(NSInteger)index
{
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)])
    {
        id <UICollectionViewDelegateFlowLayout> delegate = (id <UICollectionViewDelegateFlowLayout>) self.collectionView.delegate;

        return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:index];
    } else
    {
        return self.sectionInset;
    }
}

@end
