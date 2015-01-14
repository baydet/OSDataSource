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
@property (strong, nonatomic) OSPlaceholderFlowLayout *flowLayout;

@property(nonatomic, strong) E1DataSource *dataSource;
@end

@implementation E1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = [E1DataSource new];
    self.title = self.dataSource.title;
    self.collectionView.dataSource = self.dataSource;
    self.flowLayout = [OSPlaceholderFlowLayout new];
    self.flowLayout.estimatedItemSize = CGSizeMake(CGRectGetWidth([UIApplication sharedApplication].keyWindow.bounds), 50);
    self.flowLayout.minimumInteritemSpacing = 7;
    self.flowLayout.minimumLineSpacing = 7;
    self.collectionView.collectionViewLayout = self.flowLayout;
    [self.dataSource registerReusableViewsWithCollectionView:self.collectionView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
