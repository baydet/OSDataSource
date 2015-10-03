//
//  DataSource.swift
//  OSDataSource
//
//  Created by Alexandr Evsyuchenya on 9/27/15.
//  Copyright © 2015 baydet. All rights reserved.
//

import Foundation
import UIKit


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

public class DataSource: NSObject, UICollectionViewDataSource, DataProviderDelegate {
    private static let OSCollectionPlaceholderView = "OSCollectionPlaceholderView"
    private static let OSCollectionMoreFooterView = "OSCollectionMoreFooterView"

    internal let dataProvider: DataProvider
    public weak var delegate: DataSourceUpdates?
    
    required public init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        super.init()
        self.dataProvider.delegate = self
    }

    internal func updatePlaceholder(notifyVisibility notifyVisibility: Bool) {

    }

    internal func dequeuePlaceholderViewForCollectionView(collectionView: UICollectionView, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(DataSource.OSCollectionPlaceholderView, withReuseIdentifier: PlaceholderView.self.description(), forIndexPath: indexPath)
    }

    public func registerReusableViewsFor(collectionView: UICollectionView) {
        collectionView.registerClass(PlaceholderView.self, forSupplementaryViewOfKind: DataSource.OSCollectionPlaceholderView, withReuseIdentifier: PlaceholderView.self.description())
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

    @objc public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == DataSource.OSCollectionPlaceholderView {
            return dequeuePlaceholderViewForCollectionView(collectionView, atIndexPath:indexPath)
        }
        return UICollectionReusableView()
    }

    @objc public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    @objc public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    }


    //MARK: placeholder logic

    public var shouldDisplayPlaceholder: Bool {
        get {
            return false
        }
    }

    //MARK: DataProviderDelegate

    func dataProvider(dataProvider: DataProvider, didChangeState state: DataProvider.LoadingState) {
        switch state {
        case .Initial:
            break
        case .LoadingContent:
            break
        case .RefreshingContent:
            break
        case .LoadedContent:
            break
        case .LoadingMoreContent:
            break
        case .NoContent:
            break
        case .Error:
            break
        }
        self.updatePlaceholder(notifyVisibility: false)
    }



}


