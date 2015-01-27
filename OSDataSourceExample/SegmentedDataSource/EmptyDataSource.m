//
// Created by Alexandr Evsyuchenya on 1/14/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "EmptyDataSource.h"


@implementation EmptyDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.noContentTitle = @"There is no contnent";
        self.noContentMessage = @"Definetly";

        OSLayoutSupplementaryMetrics *supplementaryMetrics = [OSLayoutSupplementaryMetrics new];
        supplementaryMetrics.height = 300;
        self.placeholderMetrics = supplementaryMetrics;
    }

    return self;
}

- (void)loadContent
{
    [self loadContentWithObjects:nil];
}


@end