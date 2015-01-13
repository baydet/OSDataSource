//
// Created by Alexandr Evsyuchenya on 1/13/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDataSource.h"


@interface OSSimpleDataSource : OSDataSource

@property(readonly) NSArray *objects;

- (instancetype)initWithObjects:(NSArray *)objects;
- (void)loadContentWithObjects:(NSArray *)objects;


@end