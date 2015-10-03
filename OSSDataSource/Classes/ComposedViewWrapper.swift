//
// Created by Alexandr Evsyuchenya on 9/30/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation
import UIKit

internal struct ComposedMapping {
//localSectionForGlobalSection
//globalSectionForLocalSection
//localIndexPathForGlobalIndexPath
//globalIndexPathForLocalIndexPath
//localIndexPathsForGlobalIndexPaths:(NSArray *)globalIndexPaths;
//globalIndexPathsForLocalIndexPaths:(NSArray *)localIndexPaths;

//updateMappingsStartingWithGlobalSection:(NSUInteger)globalSection;
}

internal class ComposedWrapperCollectionView: UICollectionView {
    private weak var collectionView: UICollectionView?
    private let mapping: ComposedMapping

    required init(wrappedView: UICollectionView, mapping: ComposedMapping) {
        collectionView = wrappedView
        self.mapping = mapping
        super.init(frame: CGRectZero, collectionViewLayout: UICollectionViewLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        super.registerClass(cellClass, forCellWithReuseIdentifier: identifier)
    }

    override func registerClass(viewClass: AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) {
        super.registerClass(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
    }

    override func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return super.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    }

    override func dequeueReusableSupplementaryViewOfKind(elementKind: String, withReuseIdentifier identifier: String, forIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return super.dequeueReusableSupplementaryViewOfKind(elementKind, withReuseIdentifier: identifier, forIndexPath: indexPath)
    }

    override func indexPathsForSelectedItems() -> [NSIndexPath]? {
        return super.indexPathsForSelectedItems()
    }

    override func selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        super.selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition)
    }

    override func deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        super.deselectItemAtIndexPath(indexPath, animated: animated)
    }

    override func numberOfSections() -> Int {
        return super.numberOfSections()
    }

    override func numberOfItemsInSection(section: Int) -> Int {
        return super.numberOfItemsInSection(section)
    }

    override func cellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell? {
        return super.cellForItemAtIndexPath(indexPath)
    }

    override func indexPathsForVisibleItems() -> [NSIndexPath] {
        return super.indexPathsForVisibleItems()
    }

    override func supplementaryViewForElementKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return super.supplementaryViewForElementKind(elementKind, atIndexPath: indexPath)
    }


}
