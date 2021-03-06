//
//  main.m
//  OSDataSourceExample
//
//  Created by Alexandr Evsyuchenya on 1/13/15.
//  Copyright (c) 2015 baydet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "OSManagedCollectionView.h"
#import "OSPlaceholderFlowLayout.h"

int main(int argc, char * argv[]) {
    [OSManagedCollectionView class];
    [OSPlaceholderFlowLayout class];
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
