//
//  ComposedSection.swift
//  Good2Drive
//
//  Created by Alexander Evsyuchenya on 12/1/15.
//  Copyright © 2015 Engaged Mobility. All rights reserved.
//

private extension Range where Element: Comparable {
    func has(index: Element) -> Bool {
        return index >= startIndex && index < endIndex
    }
}

private class ComposedSectionMapping: Section {
    weak var updater: SectionItemsUpdatesDelegate?
    
    let range: Range<Int>
    var sectionInfo: Section
    init(globalStartIndex: Int, info: Section) {
        self.range = Range(start: globalStartIndex, end: globalStartIndex + info.numberOfSubSections())
        self.sectionInfo = info
    }
    
    private func localIndexForGlobalIndex(index: Int) -> Int{
        return index - range.startIndex
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return sectionInfo.numberOfItems(inSection: localIndexForGlobalIndex(section))
    }
    
    func numberOfSubSections() -> Int {
        return sectionInfo.numberOfSubSections()
    }
    
    subscript(indexPath: IndexPath) -> RowInfo {
        get {
            return sectionInfo[IndexPath(index: indexPath.index, section: localIndexForGlobalIndex(indexPath.section))]
        }
        set {
            sectionInfo[IndexPath(index: indexPath.index, section: localIndexForGlobalIndex(indexPath.section))] = newValue
        }
    }
    
    func decorationForSectionAtIndex(index: Int) -> SectionInfo? {
        return sectionInfo.decorationForSectionAtIndex(localIndexForGlobalIndex(index))
    }
}

public class ComposedSection: Section {
    weak public var updater: SectionItemsUpdatesDelegate?
    var sections: [Section] {
        get {
            return mappings.flatMap { $0.sectionInfo }
        }
        set {
            var startIndex: Int = 0
            
            self.mappings = newValue.flatMap {
                let mapping = ComposedSectionMapping(globalStartIndex: startIndex, info: $0)
                startIndex = mapping.range.endIndex
                return mapping
            }
            
            sections.forEach {
                $0.updater = self
            }
            updater?.notifyDidReloadData(self)
        }
    }
    
    private var mappings : [ComposedSectionMapping]
    
    public func decorationForSectionAtIndex(index: Int) -> SectionInfo? {
        return mappingForSection(index).decorationForSectionAtIndex(index)
    }
    
    init(sections: [Section]) {
        var startIndex: Int = 0
        
        self.mappings = sections.flatMap {
            let mapping = ComposedSectionMapping(globalStartIndex: startIndex, info: $0)
            startIndex = mapping.range.endIndex
            return mapping
        }
        
        sections.forEach {
            $0.updater = self
        }
    }
    
    private func mappingForSection(section: Int) -> ComposedSectionMapping {
        let filteredMappings = mappings.filter {
            $0.range.has(section)
        }
        guard let mapping = filteredMappings.first where filteredMappings.count == 1 else {
            fatalError("more the one range returned, or out of range")
        }
        return mapping
    }
    
    public func numberOfSubSections() -> Int {
        let a =  mappings.reduce(0) {
            $0 + $1.numberOfSubSections()
        }
        return a
    }
    
    public func numberOfItems(inSection section: Int) -> Int {
        return mappingForSection(section).numberOfItems(inSection: section)
    }
    
    private func mappingIndexForGlobalIndex(index: Int) -> Int {
        let ranges: [Range<Int>] = mappings.flatMap { $0.range }
        guard let index = ( ranges.indexOf { $0.has(index)}) else {
            fatalError("Out of bounds")
        }
        return index
    }
    
    public subscript(indexPath: IndexPath) -> RowInfo {
        get {
            return mappingForSection(indexPath.section)[indexPath]
        } set {
            mappings[mappingIndexForGlobalIndex(indexPath.section)][indexPath] = newValue
        }
    }
}

extension ComposedSection: SectionItemsUpdatesDelegate {
    
    func localSectionIndexToGlobal(sender: Section, _ section: Int) -> Int {
        for mapping in mappings {
            if mapping.sectionInfo === sender {
                return mapping.range.startIndex + section
            }
        }
        fatalError("unknown sender section. Probably removed")
    }
    
    public func notifyBeginUpdates(sender: Section) {
        updater?.notifyBeginUpdates(self)
    }
    
    public func notifyEndUpdates(sender: Section) {
        updater?.notifyEndUpdates(self)
    }
    
    public func notifyDeleteSections(sender: Section, sectionIndex: Int) {
        updater?.notifyDeleteSections(self, sectionIndex: localSectionIndexToGlobal(sender, sectionIndex))
    }
    
    public func notifyInsertSections(sender: Section, sectionIndex: Int) {
        updater?.notifyInsertSections(self, sectionIndex: localSectionIndexToGlobal(sender, sectionIndex))
    }
    
    public func notifyInsertRowsAtIndexPaths(sender: Section, paths: [IndexPath]) {
        let globalPathes = paths.map {
            return IndexPath(index: $0.index, section: localSectionIndexToGlobal(sender, $0.section))
        }
        updater?.notifyInsertRowsAtIndexPaths(self, paths: globalPathes)
    }
    
    public func notifyDeleteRowsAtIndexPaths(sender: Section, paths: [IndexPath]) {
        let globalPathes = paths.map {
            return IndexPath(index: $0.index, section: localSectionIndexToGlobal(sender, $0.section))
        }
        updater?.notifyDeleteRowsAtIndexPaths(self, paths: globalPathes)
    }
    
    public func notifyUpdateRowAtIndexPath(sender: Section, indexPath: IndexPath) {
        updater?.notifyUpdateRowAtIndexPath(self, indexPath: IndexPath(index: indexPath.index, section: localSectionIndexToGlobal(sender, indexPath.section)))
    }
    
    public func notifyDidReloadData(sender: Section) {
        updater?.notifyDidReloadData(self)
    }
    
    public func notifyDidRefreshSections(sender: Section, sections: [Int]) {
        let globalSections = sections.map {
            return localSectionIndexToGlobal(sender, $0)
        }
        updater?.notifyDidRefreshSections(self, sections: globalSections)
    }
}


extension ComposedSection: MutatingSection {
    public func appendRow(rowInfo: RowInfo) {
        assert(false, "append row to \(self)")
    }
    
    public func insertRow(rowInfo: RowInfo, atIndexPath indexPath: IndexPath) {
        guard let mutatingSection = mappingForSection(indexPath.section).sectionInfo as? MutatingSection else {
            fatalError("section should be mutated")
        }
        mutatingSection.insertRow(rowInfo, atIndexPath: indexPath)
    }
    
    public func deleteRow(atIndexPath indexPath: IndexPath) {
        guard let mutatingSection = mappingForSection(indexPath.section).sectionInfo as? MutatingSection else {
            fatalError("section should be mutated")
        }
        mutatingSection.deleteRow(atIndexPath: indexPath)
    }
    
}
