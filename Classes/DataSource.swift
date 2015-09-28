//
//  DataSource.swift
//  OSDataSource
//
//  Created by Alexandr Evsyuchenya on 9/27/15.
//  Copyright © 2015 baydet. All rights reserved.
//

import Foundation
import UIKit

let OSCollectionPlaceholderView = "OSCollectionPlaceholderView"

public protocol DataSourceUpdates: class {
    func dataSource(dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: DataSource, didMoveItemAtIndexPath fromIndexPaths: [NSIndexPath], toIndexPath newIndexPath: [NSIndexPath])
    func dataSource(dataSource: DataSource, didInsertSections sections: NSIndexSet)
    func dataSource(dataSource: DataSource, didRemoveSections sections: NSIndexSet)
    func dataSource(dataSource: DataSource, didMoveSection sectionIndex: NSInteger, toSection newSection: NSInteger)
    func dataSource(dataSource: DataSource, didRefreshSections sections: NSIndexSet)
    func dataSourceDidReloadData(dataSource: DataSource)
}

public class DataSource: NSObject, UICollectionViewDataSource {
    internal let dataProvider: DataProvider
    public weak var delegate: DataSourceUpdates?
    
    required public init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    public func registerReusableViewsFor(collectionView: UICollectionView) {
        collectionView.registerClass(PlaceholderView.self, forSupplementaryViewOfKind: OSCollectionPlaceholderView, withReuseIdentifier: PlaceholderView.self.description())
    }

    //MARK: UICollectionViewDataSource protocol

    @objc public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider.numberOfItems(inSection: section)
    }

    @objc public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataProvider.numberOfSections()
    }

    @objc public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        assert(false, "you must override cellForItemAtIndexPath in subclasses")
        return UICollectionViewCell()
    }
}


