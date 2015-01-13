//
// Created by Sasha Evsyuchenya on 7/28/14.
// Copyright (c) 2014 baydet. All rights reserved.
//

#import "RHeadersDataSource.h"


@implementation RHeadersDataSource

- (NSInteger)numberOfSections
{
    return [[_sectionMetrics allKeys] count];
}

- (OSLayoutSupplementaryMetrics *)addHeader
{
    return [self newHeaderForSectionAtIndex:[[_sectionMetrics allKeys] count]];
}

@end