//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "OSSimpleDataSource.h"


@interface OSSimpleDataSource ()
@property(readwrite) NSArray *objects;
@end

@implementation OSSimpleDataSource
{

}
- (instancetype)initWithObjects:(NSArray *)objects
{
    self = [super init];
    if (self)
    {
        _objects = objects;
    }

    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self loadContentWithObjects:nil];
    }

    return self;
}


- (void)loadContentWithObjects:(NSArray *)objects
{
    __weak typeof(self) weakSelf = self;
    [self loadContentWithBlock:^(AAPLLoading *loading) {
        weakSelf.objects = objects;
        if (objects.count)
        {
            if (self.objects.count)
                [loading updateWithContent:nil];
            else
                [loading updateWithContentFromEmpty:nil];
        }
        else
            [loading updateWithNoContent:nil];
    }];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.objects[(NSUInteger) indexPath.item];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.objects.count;
}

@end