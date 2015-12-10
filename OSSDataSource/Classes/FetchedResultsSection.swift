//
// Created by Alexander Evsyuchenya on 12/9/15.
// Copyright (c) 2015 baydet. All rights reserved.
//

import Foundation
import CoreData

@objc public class FetchedResultsSection: NSObject, Section, NSFetchedResultsControllerDelegate {
    public weak var updater: SectionItemsUpdatesDelegate?
    let fetchedResultsController: NSFetchedResultsController
    
    init(fetchedResultsController: NSFetchedResultsController) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
        self.fetchedResultsController.delegate = self
        let _ = try? self.fetchedResultsController.performFetch()
    }
    
    public func numberOfItems(inSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return 0
        }
        return sectionInfo.numberOfObjects
    }
    
    public func numberOfSubSections() -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    public subscript(indexPath: IndexPath) -> RowInfo {
        get {
            return fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: indexPath.index, inSection: indexPath.section)) as! RowInfo
        }
        set {
            fatalError("unimplemented")
        }
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        updater?.notifyBeginUpdates(self)
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch(type) {
            
        case .Update:
            if let indexPath = indexPath {
                updater?.notifyUpdateRowAtIndexPath(self, indexPath: indexPath.tuple)
            }
            
        case .Insert:
            if let newIndexPath = newIndexPath {
                updater?.notifyInsertRowsAtIndexPaths(self, paths: [newIndexPath.tuple])
            }
            
        case .Delete:
            if let indexPath = indexPath {
                updater?.notifyDeleteRowsAtIndexPaths(self, paths: [indexPath.tuple])
            }
            
        case .Move:
            if let indexPath = indexPath, newIndexPath = newIndexPath where indexPath != newIndexPath {
                updater?.notifyDeleteRowsAtIndexPaths(self, paths: [indexPath.tuple])
                updater?.notifyInsertRowsAtIndexPaths(self, paths: [newIndexPath.tuple])
            }
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Insert:
            updater?.notifyInsertSections(self, sectionIndex: sectionIndex)
        case .Delete:
            updater?.notifyDeleteSections(self, sectionIndex: sectionIndex)
        default:
            break
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updater?.notifyEndUpdates(self)
    }


}
