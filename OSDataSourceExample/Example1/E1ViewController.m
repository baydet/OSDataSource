//
//  E1ViewController.m
//  OSDataSourceExample
//
//  Created by Alexandr Evsyuchenya on 1/13/15.
//  Copyright (c) 2015 baydet. All rights reserved.
//

#import "E1ViewController.h"
#import "E1DataSource.h"
#import "OSPlaceholderFlowLayout.h"

@interface E1ViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet OSPlaceholderFlowLayout *flowLayout;

@property(nonatomic, strong) E1DataSource *dataSource;
@end

@implementation E1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = [E1DataSource new];
    self.collectionView.dataSource = self.dataSource;
    [self.dataSource registerReusableViewsWithCollectionView:self.collectionView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.flowLayout.estimatedItemSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 50);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
