//
// Created by Alexandr Evsyuchenya on 3/4/14.
// Copyright (c) 2014 baydet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RFlowLayoutAlignment)
{
    RCenterAlignedLayout = 0,
    RLeftAlignedLayout,
};


@interface RAlignedFlowLayout : UICollectionViewFlowLayout
@property(nonatomic, assign) RFlowLayoutAlignment contentAlignment;
@end

@protocol RAlignedFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>
@optional
- (RFlowLayoutAlignment)alignmentForFlowLayout:(RAlignedFlowLayout *)layout atIndexPath:(NSIndexPath *)path;
@end