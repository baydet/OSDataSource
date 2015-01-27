//
// Created by Alexandr Evsyuchenya on 1/14/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import "EmptyDataSource.h"


@implementation EmptyDataSource
{
    int _flag;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.noContentTitle = @"There is no contnent";
        self.noContentMessage = @"Definetly";

        self.errorMessage = @"Reload content";
        self.errorTitle = @"Error during loading";

        self.placeholderMetrics.height = 300;
        
        _flag = 0;
    }

    return self;
}

- (void)loadContent
{
    [self loadContentWithObjects:nil];
}

- (void)loadContentWithObjects:(NSArray *)objects
{
    ++_flag;
    if (_flag % 2)
    {
        [self loadContentWithBlock:^(AAPLLoading *loading) {
            [loading doneWithError:[NSError errorWithDomain:@"domain" code:0 userInfo:nil]];
        }];
    }
    else
    {
        [super loadContentWithObjects:objects];
    }
}


@end