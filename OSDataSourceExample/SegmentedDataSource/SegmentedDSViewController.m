//
// Created by Alexandr Evsyuchenya on 1/14/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "SegmentedDSViewController.h"
#import "RSegmentedDataSource.h"
#import "E1DataSource.h"
#import "EmptyDataSource.h"
#import "OSManagedCollectionView.h"

@interface SegmentedDSViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet OSManagedCollectionView *collectionView;

@property(nonatomic, strong) RSegmentedDataSource *dataSource;
@end


@implementation SegmentedDSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataSource = [RSegmentedDataSource new];
    [self.dataSource addDataSource:[E1DataSource new]];
    [self.dataSource addDataSource:[EmptyDataSource new]];
    self.collectionView.dataSource = self.dataSource;
    [self.dataSource registerReusableViewsWithCollectionView:self.collectionView];
    self.dataSource.delegate = self.collectionView;
}

- (IBAction)segmentValueChanged:(id)sender
{
    [self.dataSource setSelectedDataSourceIndex:self.segmentedControl.selectedSegmentIndex animated:YES];
}

- (IBAction)refreshContent:(id)sender
{
    [self.dataSource loadContent];
}


@end