//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "E1DataSource.h"

@interface E1Cell : UICollectionViewCell

@property(nonatomic, strong) UILabel *label;
@end

@implementation E1Cell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.label = [UILabel new];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.label.numberOfLines = 0;
        self.label.preferredMaxLayoutWidth = CGRectGetWidth([UIApplication sharedApplication].keyWindow.bounds);
        [self.contentView addSubview:self.label];

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_label]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:NSDictionaryOfVariableBindings(_label)]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
//        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    }

    return self;
}


@end

@interface E1DataSource ()
@property(nonatomic, strong) NSArray *items;
@end

@implementation E1DataSource


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.items = @[@"one", @"one oneoneoneoneone one one oneone onesfdsf one", @"oneoneoneone  oneone", @"sdfasdfa sdf as df as df as df", @"asdf as df as df asdfasdfas a", @"asdfasd asdfasdf "];
    }

    return self;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}


- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];
    [collectionView registerClass:[E1Cell class] forCellWithReuseIdentifier:NSStringFromClass([E1Cell class])];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    E1Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([E1Cell class]) forIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    cell.label.text = [self itemAtIndexPath:indexPath];
    return cell;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.items[(NSUInteger) indexPath.item];
}


@end