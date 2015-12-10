//
// Created by Alexander Evsyuchenya on 11/27/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

public protocol SectionInfo {
    
}

public protocol RowInfo {
    
}

public struct IndexPath {
    public let index: Int
    public let section: Int
}

public protocol SectionItemsUpdatesDelegate: class {
    func notifyBeginUpdates(sender: Section)
    func notifyEndUpdates(sender: Section)
    func notifyDeleteSections(sender: Section, sectionIndex: Int)
    func notifyInsertSections(sender: Section, sectionIndex: Int)
    func notifyInsertRowsAtIndexPaths(sender: Section, paths: [IndexPath])
    func notifyDeleteRowsAtIndexPaths(sender: Section, paths: [IndexPath])
    func notifyUpdateRowAtIndexPath(sender: Section, indexPath: IndexPath)
    func notifyDidReloadData(sender: Section)
    func notifyDidRefreshSections(sender: Section, sections: [Int])
}

public protocol Section: class {
    weak var updater: SectionItemsUpdatesDelegate? { get set}

    func numberOfItems(inSection section: Int) -> Int
    func numberOfSubSections() -> Int
    
    subscript(indexPath: IndexPath) -> RowInfo { get set } //after introducing throws for subscript this function will throw
    func decorationForSectionAtIndex(index: Int) -> SectionInfo?
}

public extension Section {
    func forEach(@noescape block: (RowInfo, IndexPath) -> Void) {
        let sectionsCount = numberOfSubSections()
        for i in 0...sectionsCount-1 {
            let rowsCount = numberOfItems(inSection: i)
            for j in 0...rowsCount-1 {
                let path = IndexPath(index: j, section: i)
                block(self[path], path)
            }
        }
    }
}

public protocol MutatingSection: class {
    func appendRow(rowInfo: RowInfo)
    func insertRow(rowInfo: RowInfo, atIndexPath indexPath: IndexPath)
    func deleteRow(atIndexPath indexPath: IndexPath)
}

public extension Section {

    public func decorationForSectionAtIndex(index: Int) -> SectionInfo? {
        if let decorable = self as? SectionDecoration where index == 0 {
            return decorable.sectionInfo
        }
        return nil
    }
}

public protocol SectionDecoration {
    var sectionInfo: SectionInfo? { get }
}

public enum DataProviderError: ErrorType {
    case OutOfBounds
}

public class ArraySection: Section, SectionDecoration {
    public weak var updater: SectionItemsUpdatesDelegate?
    
    public var items: [RowInfo] {
        didSet {
            updater?.notifyDidRefreshSections(self, sections: [0])
        }
    }
    
    init(items: [RowInfo], sectionInfo: SectionInfo? = nil) {
        self.items = items
        self.sectionInfo = sectionInfo
    }

    public let sectionInfo: SectionInfo?
    
    public func numberOfItems(inSection section: Int) -> Int {
        guard section == 0 else {
            fatalError("have no non zero section")
        }
        return items.count
    }
    
    public func numberOfSubSections() -> Int {
        return 1
    }
    
    public subscript(indexPath: IndexPath) -> RowInfo {
        get {
            guard indexPath.section == 0 else {
                fatalError("\(self) has only one section")
            }
            return items[indexPath.index]
        }
        set {
            items[indexPath.index] = newValue
            updater?.notifyUpdateRowAtIndexPath(self, indexPath: indexPath)
        }
    }
    
}

extension ArraySection: MutatingSection {
    
    public func appendRow(rowInfo: RowInfo) {
        items.append(rowInfo)
    }
    
    public func insertRow(rowInfo: RowInfo, atIndexPath indexPath: IndexPath) {
        if indexPath.section != 0 {
            fatalError("Out of bounds")
        }
        items.insert(rowInfo, atIndex: indexPath.index)
    }
    
    public func deleteRow(atIndexPath indexPath: IndexPath) {
        if indexPath.section != 0 {
            fatalError("Out of bounds")
        }
        updater?.notifyBeginUpdates(self)
        items.removeAtIndex(indexPath.index)
        updater?.notifyDeleteRowsAtIndexPaths(self, paths: [indexPath])
        updater?.notifyEndUpdates(self)
    }
}

public extension NSIndexPath {
    public var tuple: IndexPath {
        return IndexPath(index: item, section: section)
    }
}
