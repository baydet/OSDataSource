//
// Created by Alexandr Evsyuchenya on 1/14/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "SegmentedDSViewController.h"
#import "RSegmentedDataSource.h"
#import "E1DataSource.h"
#import "EmptyDataSource.h"

@interface SegmentedDSViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end


@implementation SegmentedDSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    RSegmentedDataSource *dataSource = [RSegmentedDataSource new];
    [dataSource addDataSource:[E1DataSource new]];
    [dataSource addDataSource:[EmptyDataSource new]];
    self.collectionView.dataSource = dataSource;
    [dataSource registerReusableViewsWithCollectionView:self.collectionView];
}

- (IBAction)segmentValueChanged:(id)sender
{

}

@end