//
// Created by Alexandr Evsyuchenya on 1/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "ComposedViewController.h"
#import "OSManagedCollectionView.h"
#import "RComposedDataSource.h"
#import "E1DataSource.h"
#import "EmptyDataSource.h"

@interface ComposedViewController ()
@property (weak, nonatomic) IBOutlet OSManagedCollectionView *collectionView;
@property(nonatomic, strong) RComposedDataSource *dataSource;
@end

@implementation ComposedViewController

- (void)viewDidLoad
{
    self.dataSource = [RComposedDataSource new];
    [self.dataSource addDataSource:[E1DataSource new]];
    [self.dataSource addDataSource:[EmptyDataSource new]];
    self.collectionView.dataSource = self.dataSource;
    [self.dataSource registerReusableViewsWithCollectionView:self.collectionView];
    self.dataSource.delegate = self.collectionView;
    [super viewDidLoad];
}


@end